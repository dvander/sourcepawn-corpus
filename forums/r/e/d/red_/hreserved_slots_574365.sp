#pragma semicolon 1

#include <sourcemod>


//
// thanks: some code is inspired by reservedslots.sp delivered with sourcemod
//

/* CHANGELOG
*
* 1.3.1-r1: testing for changed behaviour of player count on connect
* 1.3.1: added center message for redirection
* 1.3: added config file hreserved_slots.cfg
* 1.2.4: fixed bug on highest ping selection
* 1.2.3: fixed bug on hooking on cvar sm_hreserved_slots_enable causing the same player to be selected for dropping multiple times
* 1.2.2: changed GetClientCount(false) to GetClientCount(true); ?maybe? this leads to unspecified behaviour for some configs
* 1.2.1: minor change for estimation of curently connected players (just to make the code more clear; no functional change); extended hrs_status screen
* 1.2: removed redundant call on debug-output; added cvar sm_hreserved_bot_protection; made hrs_status an official command (cleaned up output & restricted access to admins with generic admin flag); hooking on cvar sm_hreserved_slots_enable to make slots to be freed if plugin is enabled at runtime
* 1.1: added client redirection option as an alternative for kicking; major code cleanups; removed depecated cvar sm_hidden_slots_reserved
* 1.0.8: added option sm_hreserved_drop_select
* 1.0.7: added custom options sm_hreserved_admin_protection, sm_hreserved_immunity_decrement, sm_hreserved_use_immunity, sm_hreserved_drop_method
* 1.0.6: added sm_hreserved_slots_amount, changed enable variable from sm_hidden_slots_reserved to sm_hreserved_slots_enable (old name was inappropriate for new function with visible reserved slots)
* 1.0.5 beta: first public release
*/

/********************************************************************
 *
 * Definitions
 *
 ********************************************************************/
 
#define PLUGIN_VERSION "1.3.1-r1"

#define MAXPLAYERS 64
#define INVALID -200
#define UNKICKABLE -100
#define TRANSLATION_FILE "hreservedslots.phrases"

#define DROP_METHOD_NONE 0
#define DROP_METHOD_KICK 1
#define DROP_METHOD_REDIRECT 2

#define DROP_SELECTION_PING 0
#define DROP_SELECTION_CONNECTION_TIME 1

#define ADMIN_PROTECTION_NONE 0
#define ADMIN_PROTECTION_NOT_SPECTATOR 1
#define ADMIN_PROTECTION_ALL 2

#define TEAM_SPECTATOR 1

/********************************************************************
 *
 * Static declarations
 *
 ********************************************************************/
 
new Handle:s_svVisiblemaxplayers;
new Handle:s_smHreservedSlotsEnable;
new Handle:s_smHreservedSlotsAmount;
new Handle:s_smHreservedAdminProtection;
new Handle:s_smHreservedImmunityDecrement;
new Handle:s_smHreservedUseImmunity;
new Handle:s_smHreservedDropMethod;
new Handle:s_smHreservedDropSelect;
new Handle:s_smHreservedRedirectTarget;
new Handle:s_smHreservedRedirectTimer;
new Handle:s_smHreservedBotProtection;

new s_priorityVector[MAXPLAYERS+1]; // will become a problem for server with more than 64 players




/********************************************************************
 *
 * Global Callbacks
 *
 ********************************************************************/
 
public Plugin:myinfo = 
{
	name = "HANSE Reserved Slots",
	author = "red!",
	description = "Provides mani admin-style slots reservation",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};


/*
 * Plugin Start Callback triggered by sourcemod on plugin initialization
 * 
 * parameters: -
 * return: -
 */
 
public OnPluginStart()
{
	LoadTranslations(TRANSLATION_FILE);
	CreateConVar("hreserved_slots", PLUGIN_VERSION, "Version of [HANSE] Reserved Slots", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	RegConsoleCmd("hrs_status", debugPrint);
	
	
	// register console cvars
	
	s_svVisiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	
	s_smHreservedSlotsEnable = CreateConVar("sm_hreserved_slots_enable", "1", "disable/enable reserved slots");
	HookConVarChange(s_smHreservedSlotsEnable, OnPluginEnabled); // new for 1.2
	s_smHreservedSlotsAmount = CreateConVar("sm_hreserved_slots_amount", "-1", "number of reserved slots (do not specify or set to -1 to automatically use hidden slots as reserved)");
	s_smHreservedAdminProtection = CreateConVar("sm_hreserved_admin_protection", "1", "protect admins from beeing dropped from server by reserved slot access (0: no protection, 1: except spec mode, 2: full protection)");
	s_smHreservedUseImmunity = CreateConVar("sm_hreserved_use_immunity", "1", "use sourcemod immunity level to find a player to be dropped (0: do not use immunity , 1: use immunity level)");
	s_smHreservedImmunityDecrement = CreateConVar("sm_hreserved_immunity_decrement", "1", "value to be subtracted from the immunity level of spectators. The value 0 will make spectators to be treated like players in the game");
	s_smHreservedRedirectTarget = CreateConVar("sm_hreserved_redirect_target", "", "alternate server a client is offered to be redirected to, if sm_hreserved_drop_method is set to value 2");
	s_smHreservedRedirectTimer = CreateConVar("sm_hreserved_redirect_timer", "12", "time to show the redirection offer dialog");
	s_smHreservedDropMethod = CreateConVar("sm_hreserved_drop_method", "1", "method for dropping players to free a reserved slot (0: no players are dropped from server, 1: kick, 2: offer to be redirected to the server specified in sm_hreserved_redirect_target)");
	s_smHreservedDropSelect = CreateConVar("sm_hreserved_drop_select", "0", "select how players are chosen to be dropped from server when there are multiple targets with the same priority. (0: highest ping, 1: shortest connection time)");
	// new for 1.2
	s_smHreservedBotProtection = CreateConVar("sm_hreserved_bot_protection", "0", "kick bots/fake clients (e.g. SourceTV)? (0: kick, 1:  do not kick)");

	// new for 1.3
	AutoExecConfig(true, "hreserved_slots");
	
}



/*
 * Callback triggered by sourcemod on client connection
 * 
 * parameters: client: client slot id (0 to maxplayers-1)
 * return: -
 */
 
public OnClientPostAdminCheck(clientSlot)
{
	// plugin deactivated
	if (GetConVarInt(s_smHreservedSlotsEnable)==0) return;
	
	new currentClientCount = GetClientCount(true); // changed for 1.3.1-r1
	new publicSlots = getPublicSlots();
	
	new userFlags = GetUserFlagBits(clientSlot);
		
	if (currentClientCount <= publicSlots ) // public slots free?
	{
		// public slots available
		PrintToServer("[hreserved_slots] public slot used (%d/%d)", currentClientCount, publicSlots);
		PrintToConsole(clientSlot,"[hreserved_slots] public slot used (%d/%d)", currentClientCount, publicSlots);
		return;
	}
	else 
	{
		// public slots full
		if (userFlags & ADMFLAG_ROOT || userFlags & ADMFLAG_RESERVATION) // is allowed to use reserved slot?
		{
			// is admin -> drop other player
			PrintToServer("[hreserved_slots] connected to reserved slot, admin rights granted");
			PrintToConsole(clientSlot,"[hreserved_slots] connected to reserved slot, admin rights granted");
			
			if (GetConVarInt(s_smHreservedDropMethod)!=DROP_METHOD_NONE) 
			{
				// calculate list of connected clients with their priority for beeing dropped
				refreshPriorityVector();
				DropPlayerByWeight();
			}
		}
		else
		{
			// not admin -> drop this player
			PrintToServer("[hreserved_slots] no free public slots");
			PrintToConsole(clientSlot,"[hreserved_slots] sorry, no free public slots");
			
			if (GetConVarInt(s_smHreservedDropMethod)==DROP_METHOD_REDIRECT) {
				CreateTimer(5.0, OnTimedRedirect, GetClientUserId(clientSlot));
			} else {
				CreateTimer(0.1, OnTimedKickForReject, GetClientUserId(clientSlot));
			}
		}
	}
	
	
}



/********************************************************************
 *
 * Custom Functions
 *
 ********************************************************************/

/*
* hook for changes on enable-variable
*
* parameters: -
* return: -
*/
public OnPluginEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarInt(s_smHreservedSlotsEnable)>0) 
	{
		PrintToServer("[hreserved_slots] plugin enabled");
		if (GetConVarInt(s_smHreservedDropMethod)!=DROP_METHOD_NONE)
		{
			// calculate list of connected clients with their priority for beeing dropped
			refreshPriorityVector();
			
			for (new i=getPublicSlots(); i<GetClientCount(true); i++) 
			{
				DropPlayerByWeight();
			}				
		}
	}
	
}

/*
* evaluate number of visible player slots
*
* parameters: -
* return: number of slots
*/
getVisibleSlots(){
		
	// estimate number of visible slots
	new visibleSlots;
	if (s_svVisiblemaxplayers==INVALID_HANDLE || GetConVarInt(s_svVisiblemaxplayers)==-1) 	
		visibleSlots = GetMaxClients(); // if sv_visiblemaxplayers is undefined all slots are visible
	else
		visibleSlots = GetConVarInt(s_svVisiblemaxplayers);

	return visibleSlots;
}

/*
* evaluate number of public player slots
*
* parameters: -
* return: number of slots
*/
getPublicSlots(){
	new maxClients = GetMaxClients();
		
	// estimate number of visible slots
	new visibleSlots = getVisibleSlots();

	
	// calculate the numer of reserved slots	
	new reservedSlots = GetConVarInt(s_smHreservedSlotsAmount);
	if (reservedSlots==-1) {
		// if reserved slots are not specified explicitely, use numer of hidden slots
		// if there are neither an explicit number of reserved slots nor hidden slots, reservedSlots will be 0 and disable the plugin
		reservedSlots=maxClients-visibleSlots; 
		PrintToServer("[hreserved_slots] no slot amount defined, using %d hidden slots as reserved.", reservedSlots);
	}
	
	// number of slots free for everyone
	return (maxClients-reservedSlots);
}


 
/*
 * evaluate plugin configuration, select corresponding client to be dropped from server and kick it to free a reserved slot 
 * called by OnClientPostAdminCheck if not DROP_METHOD_NONE
 *
 * parameters: -
 * return: -
 */
 
bool:DropPlayerByWeight() {
	new String:playername[50];

	new lowestImmunity = getLowestImmunity();
	
	if (lowestImmunity>UNKICKABLE)
	{
		new target = findDropTarget(lowestImmunity); // find the target as configured by configuration cvars
		s_priorityVector[target]=UNKICKABLE; // fix to ensure not to select the same player multiple times (marker will be removed with next call to refreshPriorityVector())
		
		GetClientName(target, playername, 49);
		PrintToServer("[hreserved_slots] dropping %s", playername);
		
		if (GetConVarInt(s_smHreservedDropMethod)==DROP_METHOD_REDIRECT) {
			CreateTimer(0.1, OnTimedRedirect, GetClientUserId(target)); 
		} else {
			CreateTimer(0.1, OnTimedKickToFreeSlot, GetClientUserId(target)); 
		}
		return true;

	} 
	
	PrintToServer("[hreserved_slots] no matching client found to kick");
	return false;
}




/*
* search s_priorityVector for the lowest available immunity group
*
* parameters: -
* return: lowest immunity group available
*/
getLowestImmunity()
{
	new lowestImmunity = INVALID; // is this is still invalid after passing through all clients, no target is found which can be dropped
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		// estimate the lowest priority group available
		if (s_priorityVector[i]>UNKICKABLE) {
			// kickable slot
			if (lowestImmunity==INVALID) lowestImmunity=s_priorityVector[i]; // overwrite invalid start entry
			if (s_priorityVector[i]<lowestImmunity) lowestImmunity=s_priorityVector[i];
		}
	}
	
	return lowestImmunity;
}

/*
 * refresh all entries in static structure s_priorityVector
 * the priority vector assigns all clients a priority for being dropped from server regarding the configuration cvars
 *
 * parameters: -
 * return: -
 */
 
 refreshPriorityVector() {

	new immunity;
	new AdminId:aid;
	new bool:hasReserved;
	
	
	
	// enumerate all clients
	for (new i=GetMaxClients();i>0;i-- )
	{
		// check if this player slot is connected and initialized
		if (IsClientInGame(i))
		{
			 
			// estimate immunity level and state of reserved slot admin flag
			aid = GetUserAdmin(i);
			if (aid==INVALID_ADMIN_ID)
			{
				// not an admin
				immunity=0;
				hasReserved=false;
			} else {
				immunity = GetAdminImmunityLevel(aid);
				hasReserved=GetAdminFlag(aid, Admin_Reservation);
			}
			
			// if set to zero, do not use immunity flag
			if (GetConVarInt(s_smHreservedUseImmunity)==0) {
				immunity=0;
			}
			
			// decrement immunity level for spectators
			if (GetClientTeam(i)==TEAM_SPECTATOR) {
				// player is spectator
				immunity-=GetConVarInt(s_smHreservedImmunityDecrement); // immunity level is decreased to make this player being kicked before players of same immunity				
			} 
			
			// calculate special permissions for admins
			if (hasReserved) {
				switch (GetConVarInt(s_smHreservedAdminProtection)) {
					case ADMIN_PROTECTION_ALL: {
						immunity = UNKICKABLE; // always denote as an unused/unkickable slot
					}
					case ADMIN_PROTECTION_NOT_SPECTATOR: {
						if (GetClientTeam(i)!=TEAM_SPECTATOR) immunity = UNKICKABLE; // denote as an unused/unkickable slot if not in spectator mode
					}
					default:	// 0: do not protect admins beside their immunity level
						{}
				}		
			}
			
			// if bots are configured not to be kicked
			if (GetConVarInt(s_smHreservedBotProtection)>0 && IsFakeClient(i)) {
				immunity = UNKICKABLE; // denote as an unused/unkickable slot
			}
			
		} else { // if (IsClientInGame(i))
			immunity = UNKICKABLE; // denote as an unused/unkickable slot
		} // if (IsClientInGame(i))
		
		// enter the calculated priority to the priority Vector
		s_priorityVector[i]=immunity;
		
		
			
		
	} // for
	
}



/*
 * refresh and print the priorityVector as well as all results from the drop selection algorithms
 *
 * parameters: clientSlot: client console this is printed to
 * return: -
 */

printPriorityVector(clientSlot) {
	new String:playername[50];
	new String:immunity[16];
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		if (IsClientInGame(i)) {
			GetClientName(i, playername, 49);
		}else{
			playername="not connected";
		}
		
		if (s_priorityVector[i]<=UNKICKABLE) 
		{
			immunity="unkickable";
		}
		else
		{
			Format(immunity, 15, "%d", s_priorityVector[i]);
		}
		PrintToConsole(clientSlot,"[hreserved_slots] id: %d, name: %s, immunity: %s", i, playername, immunity);
	}
	new lowest_immunity = getLowestImmunity();
	PrintToConsole(clientSlot,"[hreserved_slots] maximum slots: %d", GetMaxClients());
	PrintToConsole(clientSlot,"[hreserved_slots] visible slots: %d", getVisibleSlots());
	PrintToConsole(clientSlot,"[hreserved_slots] public slots: %d", getPublicSlots());
	PrintToConsole(clientSlot,"[hreserved_slots] minimum_immunity: %d", lowest_immunity);
	PrintToConsole(clientSlot,"[hreserved_slots] highest ping target: %d", findHighestPing(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] shortest connect target: %d", findShortestConnect(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] pre 1.0.8 target: %d", selectAnyPlayer(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] selected target: %d", findDropTarget(lowest_immunity));
}




/*
 * command target for debug command hrs_status
 *
 * parameters: clientSlot: client console this is printed to
 * return: -
 */
public Action:debugPrint(clientSlot, args)
{
	// slot 0 is server console. we normally trust console users ... ;-)
	if (clientSlot>0) { 
		// estimate immunity level and state of reserved slot admin flag
		new AdminId:aid = GetUserAdmin(clientSlot);
		if (aid==INVALID_ADMIN_ID || !GetAdminFlag(aid, Admin_Generic))
		{
			PrintToConsole(clientSlot,"[hreserved_slots] you do not have the rights to access this command");
			return Plugin_Handled;
		}
	}
			
	refreshPriorityVector();
	printPriorityVector(clientSlot);
	return Plugin_Handled;
}






/*
 * estimate the drop target matching the configuration; called by DropPlayerByWeight after the priority vector has been refreshed
 *
 * parameters: -
 * return: client slot selected for dropping client
 */
findDropTarget(lowestImmunity) {
	new targetSlot;
	
	switch (GetConVarInt(s_smHreservedDropSelect)) {
		case DROP_SELECTION_CONNECTION_TIME: 
			targetSlot=findShortestConnect(lowestImmunity);
		default: 
			targetSlot=findHighestPing(lowestImmunity);
	}
	if (targetSlot == -1) targetSlot=selectAnyPlayer(lowestImmunity); // last aid, select anybody
	
	return targetSlot;
}







/********************************************************************
 * Drop target selection algorithms for given immnunity group; called by findDropTarget()
 ********************************************************************/

findHighestPing(immunity_group)
{
	new Float:hping = Float:-1.0;
	new target=-1;
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		if ((s_priorityVector[i]==immunity_group) && !IsFakeClient(i) && (GetClientAvgLatency(i, NetFlow_Both) >= hping)) {
			hping=GetClientAvgLatency(i, NetFlow_Both);
			target=i;
		}
	}

	return target;
}

findShortestConnect(immunity_group)
{
	new Float:ctime = Float:-1.0;
	new target=-1;
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		if ((s_priorityVector[i]==immunity_group) && !IsFakeClient(i)) {
			if ((ctime < Float:0.0) || (GetClientTime(i)<ctime)) {
				ctime = GetClientTime(i);
				target=i;
			}
		}
	}

	return target;
}

selectAnyPlayer(immunity_group)
{
	for (new i=GetMaxClients();i>0;i-- )
	{
		if ((s_priorityVector[i]==immunity_group)) {
			return i;
		}
	}

	return -1;
}





/********************************************************************
 * Drop method implementations for delayed execution; called by DropPlayerByWeight()  or OnClientPostAdminCheck(...)
 ********************************************************************/

public Action:OnTimedKickForReject(Handle:timer, any:value)
{
	new clientSlot = GetClientOfUserId(value);
	
	if (!clientSlot || !IsClientInGame(clientSlot))
	{
		return Plugin_Handled;
	}

	KickClient(clientSlot, "%T", "no free slots", clientSlot);
	return Plugin_Handled;
}

public Action:OnTimedKickToFreeSlot(Handle:timer, any:value)
{
	new clientSlot = GetClientOfUserId(value);
	
	if (!clientSlot || !IsClientInGame(clientSlot))
	{
		return Plugin_Handled;
	}

	KickClient(clientSlot, "%T", "kicked for free slot", clientSlot);
	return Plugin_Handled;
}




public Action:OnTimedRedirect(Handle:timer, any:value)
{
	new client = GetClientOfUserId(value);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new String:target[128];
	GetConVarString(s_smHreservedRedirectTarget, target, 128); 
	
	new Float:displayTime = GetConVarFloat(s_smHreservedRedirectTimer);
	
	CreateTimer(displayTime, OnTimedKickToFreeSlot, value);
	DisplayAskConnectBox(client, displayTime, target);

	PrintCenterText(client, "%T", "server offers to reconnect", client); // new for 1.3.1
	
	return Plugin_Handled;
}





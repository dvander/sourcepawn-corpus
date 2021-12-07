#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.8 debug"

//
// USAGE: define hidden slots by using sv_visiblemaxplayers
// hidden slots will automatically be treated as reserved slots
//
// thanks: some code is inspired by reservedslots.sp delivered with sourcemod
//


public Plugin:myinfo = 
{
	name = "HANSE Reserved Slots",
	author = "red!",
	description = "Provides mani admin-style slots reservation",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};

/* Handles to convars used by plugin */
new Handle:sv_visiblemaxplayers;
new Handle:sm_hreserved_slots_enable;
new Handle:sm_hreserved_slots_amount;
new Handle:sm_hreserved_admin_protection;
new Handle:sm_hreserved_immunity_decrement;
new Handle:sm_hreserved_use_immunity;
new Handle:sm_hreserved_drop_method;
new Handle:sm_hreserved_drop_select;

new priority_vector[65]; // will become a problem for server with more than 64 players
new lowest_immunity=-200; // invalidate

public OnPluginStart()
{
	LoadTranslations("hreservedslots.phrases");
	sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	
	sm_hreserved_slots_enable = FindConVar("sm_hreserved_slots_enable");
	if (sm_hreserved_slots_enable==INVALID_HANDLE) {
		sm_hreserved_slots_enable = FindConVar("sm_hidden_slots_reserved");
		if (sm_hreserved_slots_enable==INVALID_HANDLE) {
			CreateConVar("sm_hreserved_slots_enable", "1");
			sm_hreserved_slots_enable = FindConVar("sm_hreserved_slots_enable");
		}
	}
	
	sm_hreserved_slots_amount = FindConVar("sm_hreserved_slots_amount");
	if (sm_hreserved_slots_amount==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_slots_amount", "-1");
		sm_hreserved_slots_amount = FindConVar("sm_hreserved_slots_amount");
	}
	sm_hreserved_admin_protection = FindConVar("sm_hreserved_admin_protection");
	if (sm_hreserved_admin_protection==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_admin_protection", "1");
		sm_hreserved_admin_protection = FindConVar("sm_hreserved_admin_protection");
	}
	
	sm_hreserved_immunity_decrement = FindConVar("sm_hreserved_immunity_decrement");
	if (sm_hreserved_immunity_decrement==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_immunity_decrement", "1");
		sm_hreserved_immunity_decrement = FindConVar("sm_hreserved_immunity_decrement");
	}
	
	sm_hreserved_use_immunity = FindConVar("sm_hreserved_use_immunity");
	if (sm_hreserved_use_immunity==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_use_immunity", "1");
		sm_hreserved_use_immunity = FindConVar("sm_hreserved_use_immunity");
	}
	
	sm_hreserved_drop_method = FindConVar("sm_hreserved_drop_method");
	if (sm_hreserved_drop_method==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_drop_method", "1");
		sm_hreserved_drop_method = FindConVar("sm_hreserved_drop_method");
	}
	sm_hreserved_drop_select = FindConVar("sm_hreserved_drop_select");
	if (sm_hreserved_drop_select==INVALID_HANDLE) {
		CreateConVar("sm_hreserved_drop_select", "0");
		sm_hreserved_drop_select = FindConVar("sm_hreserved_drop_select");
	}
	
	CreateConVar("hreserved_slots", PLUGIN_VERSION, "Version of [HANSE] Reserved Slots", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	RegConsoleCmd("hrs_status", debugPrint);
}


public Action:OnTimedKick(Handle:timer, any:value)
{
	new client = GetClientOfUserId(value);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	KickClient(client, "%T", "no free slots", client);
	return Plugin_Handled;
}


public Action:debugPrint(client, args)
{
	refreshPriorityVector();
	printPriorityVector(client);
	return Plugin_Handled;
}

refreshPriorityVector() {

	new immunity;
	new AdminId:aid;
	new bool:has_reserved;
	
	lowest_immunity = -200;
	
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
				has_reserved=false;
			} else {
				immunity = GetAdminImmunityLevel(aid);
				has_reserved=GetAdminFlag(aid, Admin_Reservation);
			}
			
			// if set to zero, do not use immunity flag
			if (GetConVarInt(sm_hreserved_use_immunity)==0) {
				immunity=0;
			}
			
			// decrement immunity level for spectators
			if (GetClientTeam(i)==1) {
				// player is spectator
				immunity-=GetConVarInt(sm_hreserved_immunity_decrement); // immunity level is decreased to make this player being kicked before players of same immunity				
			} 
			// calculate special permissions for admins
			if (has_reserved) {
				switch (GetConVarInt(sm_hreserved_admin_protection)) {
					case 2: {
						immunity = -100; // always denote as an unused/unkickable slot
					}
					case 1: {
						if (GetClientTeam(i)!=1) immunity = -100; // denote as an unused/unkickable slot if not in spectator mode
					}
					default:	// 0: do not protect admins beside their immunity level
						{}
				}		
			}
			
		} else {
			immunity = -100; // denote as an unused/unkickable slot
		}
		
		if (immunity>-100) {
			// not unkickable
			if (lowest_immunity==-200) lowest_immunity=immunity; // overwrite invalid start entry
			if (immunity<lowest_immunity) lowest_immunity=immunity;
		}
		priority_vector[i]=immunity;
		
	} // for
	
}

findHighestPing(immunity_group)
{
	new Float:hping = Float:-1.0;
	new target=-1;
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		if ((priority_vector[i]==immunity_group) && !IsFakeClient(i) && (GetClientAvgLatency(i, NetFlow_Both) >= hping)) {
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
		if ((priority_vector[i]==immunity_group) && !IsFakeClient(i)) {
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
		if ((priority_vector[i]==immunity_group)) {
			return i;
		}
	}

	return -1;
}

findDropTarget() {
	new target;
	switch (GetConVarInt(sm_hreserved_drop_select)) {
		case 1: 
			target=findShortestConnect(lowest_immunity);
		default: 
			target=findHighestPing(lowest_immunity);
	}
	if (target == -1) target=selectAnyPlayer(lowest_immunity);
	return target;
}


printPriorityVector(client) {
	new String:playername[50];
	refreshPriorityVector();
	
	for (new i=GetMaxClients();i>0;i-- )
	{
		if (IsClientInGame(i)) {
			GetClientName(i, playername, 49);
		}else{
			playername="not connected";
		}
		PrintToConsole(client,"[hreserved_slots] id: %d, name: %s, immunity: %d", i, playername, priority_vector [i]);
		PrintToServer("[hreserved_slots] id: %d, name: %s, immunity: %d", i, playername, priority_vector [i]);
	}
	
	PrintToConsole(client,"[hreserved_slots] minimum_immunity: %d", lowest_immunity);
	PrintToServer("[hreserved_slots] minimum_immunity: %d", lowest_immunity);
	PrintToConsole(client,"[hreserved_slots] highest ping target: %d", findHighestPing(lowest_immunity));
	PrintToServer("[hreserved_slots] highest ping target: %d", findHighestPing(lowest_immunity));
	PrintToConsole(client,"[hreserved_slots] shortest connect target: %d", findShortestConnect(lowest_immunity));
	PrintToServer("[hreserved_slots] shortest connect target: %d", findShortestConnect(lowest_immunity));
	PrintToConsole(client,"[hreserved_slots] pre 1.0.8 target: %d", selectAnyPlayer(lowest_immunity));
	PrintToServer("[hreserved_slots] pre 1.0.8 target: %d", selectAnyPlayer(lowest_immunity));
	PrintToConsole(client,"[hreserved_slots] selected target: %d", findDropTarget());
	PrintToServer("[hreserved_slots] selected target: %d", findDropTarget());
}

bool:KickByWeight(new_client) {
	new String:playername[50];

	
	refreshPriorityVector();
	//printPriorityVector(new_client);
	
	if (lowest_immunity>-100)
	{
		new target = findDropTarget();
		GetClientName(target, playername, 49);
		PrintToServer("[hreserved_slots] kicking %s", playername);
		PrintToConsole(new_client,"[hreserved_slots] kicking %s", playername);
		KickClient(target, "%T", "kicked for free slot", target);
		return true;

	} 
	
	PrintToServer("[hreserved_slots] no matching client found to kick");
	PrintToConsole(new_client,"[hreserved_slots] no matching client found to kick");
	return false;
}



public OnClientPostAdminCheck(client)
{
	// plugin deactivated
	if (GetConVarInt(sm_hreserved_slots_enable)==0) return;

	new max_clients = GetMaxClients();
	
	// estimate number of visible slots
	new visible_players;
	if (sv_visiblemaxplayers==INVALID_HANDLE || GetConVarInt(sv_visiblemaxplayers)==-1) 	
		visible_players = max_clients;
	else
		visible_players = GetConVarInt(sv_visiblemaxplayers);

	
	// calculate the numer of reserved slots	
	new reserved_slots = GetConVarInt(sm_hreserved_slots_amount);
	if (reserved_slots==-1) {
		reserved_slots=GetMaxClients()-visible_players;
		PrintToServer("[hreserved_slots] no slot amount defined, using %d hidden slots as reserved.", reserved_slots);
	}
	
	new public_slots=max_clients-reserved_slots;
	
	new clients = GetClientCount(false); 
	
	
	
	new flags = GetUserFlagBits(client);
		
	if (clients < public_slots || IsFakeClient(client))
	{
		PrintToServer("[hreserved_slots] public slot used (%d(+1)/%d)", clients, visible_players);
		PrintToConsole(client,"[hreserved_slots] public slot used (%d(+1)/%d)", clients, visible_players);
		return;
	}
	else 
	{
		if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
		{
			
			PrintToServer("[hreserved_slots] connected to reserved slot, admin rights granted");
			PrintToConsole(client,"[hreserved_slots] connected to reserved slot, admin rights granted");
			// kick other player
			if (GetConVarInt(sm_hreserved_drop_method)==1) KickByWeight(client);
		}
		else
		{
			PrintToServer("[hreserved_slots] no free public slots", clients, public_slots);
			PrintToConsole(client,"[hreserved_slots] no free public slots", clients, public_slots);
			// kick this player
			CreateTimer(0.1, OnTimedKick, GetClientUserId(client));
		}
	}
	
	
}
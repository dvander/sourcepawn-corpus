#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "3.0"

#define INVALID -200
#define UNKICKABLE -100
#define TRANSLATION_FILE "hreservedslots.phrases"

#define DROP_METHOD_NONE 0
#define DROP_METHOD_KICK 1
#define DROP_METHOD_REDIRECT 2

#define DROP_SELECTION_PING 0
#define DROP_SELECTION_CONNECTION_TIME 1
#define DROP_SELECTION_RANDOM 2
#define DROP_SELECTION_SCORE 3

#define ADMIN_PROTECTION_NONE 0
#define ADMIN_PROTECTION_NOT_SPECTATOR 1
#define ADMIN_PROTECTION_ALL 2

#define TEAM_SPECTATOR 1
#define TEAM_TEAMLESS 0

ConVar s_svVisiblemaxplayers;
ConVar s_smHreservedSlotsEnable;
ConVar s_smHreservedSlotsAmount;
ConVar s_smHreservedAdminProtection;
ConVar s_smHreservedImmunityDecrement;
ConVar s_smHreservedUseImmunity;
ConVar s_smHreservedDropMethod;
ConVar s_smHreservedDropSelect;
ConVar s_smHreservedRedirectTarget;
ConVar s_smHreservedRedirectTimer;
ConVar s_smHreservedBotProtection;
ConVar s_smAuthByTag;
ConVar s_smAuthTag;
int s_priorityVector[MAXPLAYERS+1]; 

forward bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255]);

public Extension __ext_Connect = 
{
	name = "Connect",
	file = "connect.ext",
	autoload = 1,
	required = 0,
}

public Plugin myinfo = 
{
	name = "HANSE Reserved Slots",
	author = "red!, luki1412",
	description = "Provides mani admin-style slots reservation",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
}

public void OnPluginStart()
{
	LoadTranslations(TRANSLATION_FILE);
	ConVar vers = CreateConVar("hreserved_slots", PLUGIN_VERSION, "Version of [HANSE] Reserved Slots", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("hrs_status", debugPrint);
	
	// register console cvars
	s_svVisiblemaxplayers = FindConVar("sv_visiblemaxplayers");
	s_smHreservedSlotsEnable = CreateConVar("sm_hreserved_slots_enable", "1", "disable/enable reserved slots");
	s_smHreservedSlotsAmount = CreateConVar("sm_hreserved_slots_amount", "-1", "number of reserved slots (do not specify or set to -1 to automatically use hidden slots as reserved)");
	s_smHreservedAdminProtection = CreateConVar("sm_hreserved_admin_protection", "1", "protect admins from beeing dropped from server by reserved slot access (0: no protection, 1: except spec mode, 2: full protection)");
	s_smHreservedUseImmunity = CreateConVar("sm_hreserved_use_immunity", "1", "use sourcemod immunity level to find a player to be dropped (0: do not use immunity , 1: use immunity level)");
	s_smHreservedImmunityDecrement = CreateConVar("sm_hreserved_immunity_decrement", "1", "value to be subtracted from the immunity level of spectators. The value 0 will make spectators to be treated like players in the game");
	s_smHreservedRedirectTarget = CreateConVar("sm_hreserved_redirect_target", "", "alternate server a client is offered to be redirected to, if sm_hreserved_drop_method is set to value 2");
	s_smHreservedRedirectTimer = CreateConVar("sm_hreserved_redirect_timer", "12", "time to show the redirection offer dialog");
	s_smHreservedDropMethod = CreateConVar("sm_hreserved_drop_method", "1", "method for dropping players to free a reserved slot (0: no players are dropped from server, 1: kick, 2: offer to be redirected to the server specified in sm_hreserved_redirect_target)");
	s_smHreservedDropSelect = CreateConVar("sm_hreserved_drop_select", "0", "select how players are chosen to be dropped from server when there are multiple targets with the same priority. (0: highest ping, 1: shortest connection time, 2: random)");
	s_smHreservedBotProtection = CreateConVar("sm_hreserved_bot_protection", "0", "kick bots/fake clients (e.g. SourceTV)? (0: kick, 1:  do not kick)");
	s_smAuthByTag = CreateConVar("sm_hreserved_auth_by_tag", "0", "authenticate admins by clan tag specified by sm_hreserved_auth_tag; 0: off, 1:on");
	s_smAuthTag = CreateConVar("sm_hreserved_auth_tag", "", "authentication clan tag");

	HookConVarChange(s_smHreservedSlotsEnable, OnPluginEnabled);
	
	char errBuf[40];
	int connStatus = GetExtensionFileStatus("connect.ext", errBuf, 40);
	if (connStatus == 1) 
	{
		LogMessage("'connect' extension avaiable");
	} 
	else if (connStatus != -2) 
	{
		LogMessage("'connect' extension present but inoperable due to '%s' (code %d)", errBuf, connStatus);
	}
	
	AutoExecConfig(true, "hreserved_slots");
	SetConVarString(vers, PLUGIN_VERSION);
}

public bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255])
{
	if (isPublicSlot(true))	
	{ 
		return true; 
	} 	// server not full or plugin disabled, nothing to do right now
	
	if (getReservedSlots()>0) 
	{ 
		return true; 
	} 	// server has explicitely configured reserved slots or hidden slots, let OnClientPostAdminCheck handle this ...

	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);
	
	if (admin != INVALID_ADMIN_ID)
	{
		if (hasReservedSlotAccess(name, GetAdminFlags(admin, Access_Effective)))
		{
			refreshPriorityVector();
			DropPlayerByWeight(true);
		}
	}
	
	return true;
}

public void OnClientPostAdminCheck(int clientSlot)
{
	if (isPublicSlot())	
	{ 
		return; 
	}
	else 
	{
		// public slots full
		char playername[50];
		GetClientName(clientSlot, playername, 49);
		
		if (hasReservedSlotAccess(playername, GetUserFlagBits(clientSlot)))
		{
			// is admin -> drop other player
			//PrintToServer("[hreserved_slots] connected to reserved slot, admin rights granted");
			//PrintToConsole(clientSlot,"[hreserved_slots] connected to reserved slot, admin rights granted");
			//LogMessage("admin %s connected to reserved slot", playername);
			
			if (GetConVarInt(s_smHreservedDropMethod) != DROP_METHOD_NONE) 
			{
				// calculate list of connected clients with their priority for beeing dropped
				refreshPriorityVector();
				DropPlayerByWeight();
			}
		}
		else
		{
			// not admin -> drop this player
			//PrintToServer("[hreserved_slots] no free public slots");
			//PrintToConsole(clientSlot,"[hreserved_slots] sorry, no free public slots");
			//LogMessage("unpriviledged user %s connected to reserved slot", playername);
			
			if (GetConVarInt(s_smHreservedDropMethod)==DROP_METHOD_REDIRECT) 
			{
				CreateTimer(5.0, OnTimedRedirect, GetClientUserId(clientSlot));
			} 
			else 
			{
				CreateTimer(0.1, OnTimedKickForReject, GetClientUserId(clientSlot));
			}
		}
	}
}

bool hasReservedSlotAccess(const char[] playername, int userFlags) 
{
	// tag based mode
	if (GetConVarBool(s_smAuthByTag))
	{
		char authTag[50];
		GetConVarString(s_smAuthTag, authTag, 50);
		
		if (StrContains(playername, authTag)>=0)
		{
			//LogMessage("admin %s authenticated by clan tag", playername);
			return true;
		}
	}
	
	// admin flag based 
	if (userFlags & ADMFLAG_ROOT || userFlags & ADMFLAG_RESERVATION)
	{
		return true;
	} 
	else 
	{
		return false;
	}
}

bool isPublicSlot(bool isPreconnect = false) 
{
	// plugin deactivated
	if (GetConVarInt(s_smHreservedSlotsEnable)==0) 
	{ 
		return true; 
	}

	int currentClientCount = GetClientCount(true) + ((isPreconnect) ? 1 : 0);
	int publicSlots = getPublicSlots();
	
	//PrintToServer("[hreserved_slots] public slot used: %d%s/%d", currentClientCount, (isPreconnect) ? " (incl. 1 preConnected)" : "", publicSlots);
	//PrintToConsole(clientSlot,"[hreserved_slots] public slot used (%d/%d)", currentClientCount, publicSlots);
	return (currentClientCount <= publicSlots );
}

public void OnPluginEnabled(Handle convar, const char[] oldValue, const char[] newValue) 
{
	if (GetConVarInt(s_smHreservedSlotsEnable)>0) 
	{
		//PrintToServer("[hreserved_slots] plugin enabled");
		if (GetConVarInt(s_smHreservedDropMethod) != DROP_METHOD_NONE)
		{
			// calculate list of connected clients with their priority for beeing dropped
			refreshPriorityVector();
			
			for (int i = getPublicSlots(); i < GetClientCount(true); i++) 
			{
				DropPlayerByWeight();
			}
		}
	}
}

int getVisibleSlots()
{
	// estimate number of visible slots
	int visibleSlots;
	
	if (s_svVisiblemaxplayers == null || GetConVarInt(s_svVisiblemaxplayers) == -1)
	{	
		visibleSlots = MaxClients; // if sv_visiblemaxplayers is undefined all slots are visible
	}
	else
	{
		visibleSlots = GetConVarInt(s_svVisiblemaxplayers);
	}

	return visibleSlots;
}

int getPublicSlots()
{
	// number of slots free for everyone
	return (MaxClients - getReservedSlots());
}

int getReservedSlots() 
{
	int reservedSlots = GetConVarInt(s_smHreservedSlotsAmount);
	
	if (reservedSlots==-1) 
	{
		// if reserved slots are not specified explicitely, use numer of hidden slots
		// if there are neither an explicit number of reserved slots nor hidden slots, reservedSlots will be 0 and disable the plugin
		reservedSlots = MaxClients - getVisibleSlots(); 
	}

	return reservedSlots;
}

bool DropPlayerByWeight(bool enforce = false) 
{
	char playername[50];

	int lowestImmunity = getLowestImmunity();
	
	if (lowestImmunity > UNKICKABLE)
	{
		LogMessage("selecting player of lowest immunity group (%d)", lowestImmunity);
		int target = findDropTarget(lowestImmunity); // find the target as configured by configuration cvars
		
		if (target>-1)
		{
			s_priorityVector[target]=UNKICKABLE; // fix to ensure not to select the same player multiple times (marker will be removed with next call to refreshPriorityVector())
			
			GetClientName(target, playername, 49);
			LogMessage("[hreserved_slots] dropping %s%s", playername, (enforce) ? "(enforcing method kick when using 'connect' extension)" : "");
			
			if (enforce)
			{	
				KickToFreeSlotNow(target);
			}
			else 
			{
				if ((GetConVarInt(s_smHreservedDropMethod)==DROP_METHOD_REDIRECT) && !IsFakeClient(target)) 
				{
					CreateTimer(0.1, OnTimedRedirect, GetClientUserId(target)); 
				} else {
					CreateTimer(0.1, OnTimedKickToFreeSlot, GetClientUserId(target)); 
				}
			}
			return true;
		}
	} 
	else 
	{
		LogMessage("no non-admins available to drop, giving up.");
	}
	
	LogMessage("[hreserved_slots] no matching client found to kick");
	return false;
}

int getLowestImmunity()
{
	int lowestImmunity = INVALID; // is this is still invalid after passing through all clients, no target is found which can be dropped
	
	for (int i=MaxClients; i>0 ;i-- )
	{
		// estimate the lowest priority group available
		if (s_priorityVector[i]>UNKICKABLE) 
		{
			// kickable slot
			if (lowestImmunity==INVALID) 
			{
				lowestImmunity=s_priorityVector[i]; // overwrite invalid start entry
			}
			
			if (s_priorityVector[i]<lowestImmunity)
			{
				lowestImmunity=s_priorityVector[i];
			}
		}
	}
	
	return lowestImmunity;
}

void refreshPriorityVector() 
{
	int immunity;
	AdminId aid;
	bool hasReserved;
	
	// enumerate all clients
	for (int i = MaxClients; i>0; i-- )
	{
		// check if this player slot is connected and initialized
		if (IsClientInGame(i))
		{
			// estimate immunity level and state of reserved slot admin flag
			aid = GetUserAdmin(i);
			if (aid==INVALID_ADMIN_ID)
			{
				// not an admin
				immunity = 0;
				hasReserved = false;
			} 
			else 
			{
				immunity = GetAdminImmunityLevel(aid);
				hasReserved = GetAdminFlag(aid, Admin_Reservation);
			}
			
			// if set to zero, do not use immunity flag
			if (GetConVarInt(s_smHreservedUseImmunity) == 0) 
			{
				immunity = 0;
			}
			
			// decrement immunity level for spectators
			if (( GetClientTeam(i) == TEAM_TEAMLESS) || (GetClientTeam(i) == TEAM_SPECTATOR)) 
			{
				// player is spectator
				immunity -= GetConVarInt(s_smHreservedImmunityDecrement); // immunity level is decreased to make this player being kicked before players of same immunity				
			} 
			
			// calculate special permissions for admins
			if (hasReserved) 
			{
				switch (GetConVarInt(s_smHreservedAdminProtection)) 
				{
					case ADMIN_PROTECTION_ALL: 
					{
						immunity = UNKICKABLE; // always denote as an unused/unkickable slot
					}
					case ADMIN_PROTECTION_NOT_SPECTATOR: 
					{
						if (GetClientTeam(i) != TEAM_SPECTATOR) 
						{ 
							immunity = UNKICKABLE; 
						} // denote as an unused/unkickable slot if not in spectator mode
					}
					default:	// 0: do not protect admins beside their immunity level
					{
					}
				}		
			}
			
			// if bots are configured not to be kicked
			if (GetConVarInt(s_smHreservedBotProtection)>0 && IsFakeClient(i)) 
			{
				immunity = UNKICKABLE; // denote as an unused/unkickable slot
			}
			
		} 
		else 
		{
			immunity = UNKICKABLE; // denote as an unused/unkickable slot
		}
		
		s_priorityVector[i]=immunity;
	}
}

void printPriorityVector(int clientSlot) 
{
	char playername[50];
	char immunity[16];
	
	for (int i = MaxClients; i > 0; i-- )
	{
		if (IsClientInGame(i)) 
		{
			GetClientName(i, playername, 49);
		}
		else
		{
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
	
	int lowest_immunity = getLowestImmunity();
	int reservedSlots = getReservedSlots();
	
	PrintToConsole(clientSlot,"[hreserved_slots] maximum slots: %d", MaxClients);
	PrintToConsole(clientSlot,"[hreserved_slots] visible slots: %d", getVisibleSlots());
	PrintToConsole(clientSlot,"[hreserved_slots] public slots: %d", getPublicSlots());
	PrintToConsole(clientSlot,"[hreserved_slots] reserved slots: %d (%s)", reservedSlots, (reservedSlots == 0) ? "using connect.ext if present" : (GetConVarInt(s_smHreservedSlotsAmount)==-1) ? "using hidden slots" : "user configured");
	PrintToConsole(clientSlot,"[hreserved_slots] minimum_immunity: %d", lowest_immunity);
	PrintToConsole(clientSlot,"[hreserved_slots] highest ping target: %d", findHighestPing(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] shortest connect target: %d", findShortestConnect(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] random target: %d", findRandomTarget(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] pre 1.0.8 target: %d", selectAnyPlayer(lowest_immunity));
	PrintToConsole(clientSlot,"[hreserved_slots] selected target: %d", findDropTarget(lowest_immunity));
}

public Action debugPrint(int clientSlot, int args)
{
	// slot 0 is server console. we normally trust console users ... ;-)
	if (clientSlot > 0) 
	{ 
		// estimate immunity level and state of reserved slot admin flag
		AdminId aid = GetUserAdmin(clientSlot);
		
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

int findDropTarget(int lowestImmunity) 
{
	int targetSlot;
	
	switch (GetConVarInt(s_smHreservedDropSelect)) 
	{
		//case DROP_SELECTION_SCORE:
		//	targetSlot = findHighestScoreTarget(lowestImmunity);
		case DROP_SELECTION_RANDOM:
		{
			targetSlot = findRandomTarget(lowestImmunity);
		}
		case DROP_SELECTION_CONNECTION_TIME: 
		{
			targetSlot = findShortestConnect(lowestImmunity);
		}
		case DROP_SELECTION_PING:
		{
			targetSlot = findHighestPing(lowestImmunity);
		}
		default:
		{
			targetSlot = findHighestPing(lowestImmunity);
		}
	}
	
	if (targetSlot == -1) 
	{
		targetSlot = selectAnyPlayer(lowestImmunity); // last aid, select anybody
	}
	
	return targetSlot;
}

int findRandomTarget(int immunity_group)
{
	int targetCount = 0;
	int target = -1;
	
	for (int i = MaxClients; i>0; i-- )
	{
		if ((s_priorityVector[i]==immunity_group) && !IsFakeClient(i)) 
		{
			targetCount++;
		}
	}
	
	if (targetCount > 0)
	{
		int targetInGroup = GetRandomInt(1, targetCount);
		
		for (int j=MaxClients; j>0; j-- )
		{
			if ((s_priorityVector[j]==immunity_group) && !IsFakeClient(j)) 
			{
				targetInGroup--;
				
				if (targetInGroup==0) 
				{
					target=j;
				}
			}
		}
	}
	
	if (target!=-1) 
	{ 
		LogMessage("selected random target %d", target); 
	}
	
	return target;
}

int findHighestPing(int immunity_group)
{
	float hping = -1.0;
	int target = -1;
	
	for (int i = MaxClients; i > 0; i-- )
	{
		if ((s_priorityVector[i] == immunity_group) && !IsFakeClient(i) && (GetClientAvgLatency(i, NetFlow_Both) >= hping)) 
		{
			hping=GetClientAvgLatency(i, NetFlow_Both);
			target=i;
		}
	}
	if (target != -1) 
	{ 
		LogMessage("selected highest ping target %d", target); 
	}
	return target;
}

int findShortestConnect(int immunity_group)
{
	float ctime = -1.0;
	int target = -1;
	
	for (int i = MaxClients; i > 0; i-- )
	{
		if ((s_priorityVector[i]==immunity_group) && !IsFakeClient(i)) 
		{
			if ((ctime < 0.0) || (GetClientTime(i)<ctime)) 
			{
				ctime = GetClientTime(i);
				target = i;
			}
		}
	}
	
	if (target!=-1) 
	{ 
		LogMessage("selected shortest connected target %d", target); 
	}
	
	return target;
}

int selectAnyPlayer(int immunity_group)
{
	for (int i = MaxClients; i > 0; i-- )
	{
		if ((s_priorityVector[i]==immunity_group)) 
		{
			LogMessage("emergency selection of target %d", i); 
			return i;
		}
	}

	return -1;
}

public Action OnTimedKickForReject(Handle timer, any value)
{
	int clientSlot = GetClientOfUserId(value);
	
	if (!clientSlot || !IsClientInGame(clientSlot))
	{
		return Plugin_Handled;
	}

	char playername[50];
	GetClientName(clientSlot, playername, 49);
	char playerid[50];
	GetClientAuthId(clientSlot, AuthId_Steam2, playerid, 49);
	LogMessage("kicking rejected player %s [%s]", playername, playerid);
	
	KickClient(clientSlot, "%T", "no free slots", clientSlot);
	return Plugin_Handled;
}

public Action OnTimedKickToFreeSlot(Handle timer, any value)
{
	int clientSlot = GetClientOfUserId(value);
	
	KickToFreeSlotNow(clientSlot);
	return Plugin_Handled;
}

void KickToFreeSlotNow(int clientSlot) 
{
	if (!clientSlot || !IsClientInGame(clientSlot))
	{
		return;
	} 
	else 
	{
		char playername[50];
		GetClientName(clientSlot, playername, 49);
		char playerid[50];
		GetClientAuthId(clientSlot, AuthId_Steam2, playerid, 49);
		LogMessage("kicking player %s [%s] to free slot", playername, playerid);
		
		KickClient(clientSlot, "%T", "kicked for free slot", clientSlot);
	}
}

public Action OnTimedRedirect(Handle timer, any value)
{
	int client = GetClientOfUserId(value);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char target[128];
	GetConVarString(s_smHreservedRedirectTarget, target, 128); 
	float displayTime = GetConVarFloat(s_smHreservedRedirectTimer);
	char playername[50];
	GetClientName(client, playername, 49);
	char playerid[50];
	GetClientAuthId(client, AuthId_Steam2, playerid, 49);
	LogMessage("offering redirection to player %s [%s]", playername, playerid);
	CreateTimer(displayTime, OnTimedKickToFreeSlot, value);
	DisplayAskConnectBox(client, displayTime, target);
	PrintCenterText(client, "%T", "server offers to reconnect", client);
	
	return Plugin_Handled;
}
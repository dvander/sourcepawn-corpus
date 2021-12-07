#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PL_VERSION "1.1"

new const String:classNameArray[5][16] = 
{
	"Pistols",
	"Shotguns",
	"Sub-Machineguns",
	"Rifles/MG",
	""
};

getWeaponClassByIndex(index)
{
	new class = -1;
	if(index >= 0)
	{
		if(index < 6){class = 0;}
		else if(index < 8){class = 1;}
		else if(index < 13){class = 2;}
		else if(index < 24){class = 3;}
		else if(index < 26){class = 4;}
		else if(index < 28){class = 0;}
	}
	return class;
}

//looks a bit weird but it's different ingame
new const String:weaponNameArray[28][45] = {
    "Glock 18                        |9mm",
    "USP tactical                   |.45 ACP",
    "P228                              |.357 SIG",
    "Desert Eagle                  |.50 AE",
    "FN Five-seveN               |5.7x28mm",
    "Dual 96G Elite Berettas|9mm",
    "M3 super 90|12 gauge",
    "XM1014       |12 gauge",
    "MAC10      |.45 ACP",
    "TMP           |9mm",
    "MP5 Navy |9mm",
    "UMP45      |.45 ACP",
    "P90           |5.7x28mm",
	"Galil     |.223",
    "FAMAS |5.56",
    "AK47   |7.62",    
    "M4A1   |5.56",
    "Scout   |7.62",
    "SG552 |5.56",
    "AUG     |5.56",
    "G3SG1 |7.62",
    "SG550 |5.56",
    "AWP    |.338 Lapua Magnum",
    "M249   |5.56",
    "disable primary weapon",
    "any primary weapon",
    "disable secondary weapon",
    "any secondary weapon"
};

new String:enabledWeaponNameArray[28][45];

new const String:weaponGiveNameArray[28][18] = {
    "glock",//0
    "usp",
    "p228",
    "deagle",
    "fiveseven",
    "elite",//5
    "m3",//6
    "xm1014",//7
    "mac10",//8
    "tmp",
    "mp5navy",
    "ump45",
    "p90",//12
    "galil",//13
    "famas",
    "ak47",
    "m4a1",
    "scout",
    "sg552",
    "aug",
    "g3sg1",
    "sg550",
    "awp",
    "m249",//23
    "disable_primary",//24
    "any_primary",//25
    "disable_secondary",//26
    "any_secondary"//27
};

new const String:yesNoArray[2][8] = {
	"Accept",
	"Decline"
};

new Handle:yesNoVoteCookie;

new bool:voteInProgress;
new voteWeaponIndex;

new Handle:receivedPrimaryCookie;
new Handle:receivedSecondaryCookie;

//new Handle:primaryClassVoteCookie;
new Handle:primaryWeaponVoteCookie;
new Handle:secondaryWeaponVoteCookie;

new currentPrimaryWeaponIndex;
new currentSecondaryWeaponIndex;

new Handle:g_cvar_vwpEnabled;
new Handle:g_cvar_primaryEnabled;
new Handle:g_cvar_secondaryEnabled;
new Handle:g_cvar_ignoreBots;

public Plugin:myinfo =
{
	name = "Vote Weapon",
	author = "kumpu",
	description = "Allows players to vote for weapons.",
	version = PL_VERSION,
	url = ""
};

bool:getVwpEnabled()
{
	return (GetConVarInt(g_cvar_vwpEnabled) == 1);
}

bool:getPrimaryEnabled()
{
	return (GetConVarInt(g_cvar_primaryEnabled) == 1);
}

bool:getSecondaryEnabled()
{
	return (GetConVarInt(g_cvar_secondaryEnabled) == 1);
}

bool:getIgnoreBots()
{
	return (GetConVarInt(g_cvar_ignoreBots) == 1);
	
}

public OnPluginStart()
{
	//primaryClassVoteCookie = RegClientCookie("kumpu_vwp_primaryClassVote", "", CookieAccess_Protected);
	primaryWeaponVoteCookie = RegClientCookie("kumpu_vwp_primaryWeaponVote", "", CookieAccess_Protected);

	secondaryWeaponVoteCookie = RegClientCookie("kumpu_vwp_secondaryWeaponVote", "", CookieAccess_Protected);

	yesNoVoteCookie = RegClientCookie("kumpu_vwp_yesNo", "", CookieAccess_Protected);

	currentPrimaryWeaponIndex = -1;
	currentSecondaryWeaponIndex = -1;
	receivedPrimaryCookie = RegClientCookie("kumpu_vwp_recPrimary", "no", CookieAccess_Protected);
	receivedSecondaryCookie = RegClientCookie("kumpu_vwp_recSecondary", "no", CookieAccess_Protected);

	setEnabledWeapons();	
	doConvarStuff();
	hookVwpEvents();
	regCmds();
	CreateTimer(1.0, Timer_manageWeapons, _, TIMER_REPEAT);
}

doConvarStuff()
{
	CreateConVar("voteweapon_version", PL_VERSION, "Version of Vote Weapon plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cvar_vwpEnabled = CreateConVar("voteWeapon_enabled", "1");
	HookConVarChange(g_cvar_vwpEnabled, onBoolConvarChange);

	g_cvar_primaryEnabled = CreateConVar("voteWeapon_primary_enabled", "1");
	HookConVarChange(g_cvar_primaryEnabled, onBoolConvarChange);

	g_cvar_secondaryEnabled = CreateConVar("voteWeapon_secondary_enabled", "1");
	HookConVarChange(g_cvar_secondaryEnabled, onBoolConvarChange);

	g_cvar_ignoreBots = CreateConVar("voteWeapon_ignore_bots", "0");
	HookConVarChange(g_cvar_ignoreBots, onBoolConvarChange);

	AutoExecConfig(true, "weaponVote");
}

hookVwpEvents()
{
	HookEvent("player_spawn", Event_player_spawn, EventHookMode_Post);
}

regCmds(){
	RegConsoleCmd("vwp", startVoteCmd);
	RegConsoleCmd("voteweapon", startVoteCmd);
	RegConsoleCmd("vwphelp", helpCmd);
	RegConsoleCmd("vwplist", listCmd)

	RegAdminCmd("vwpclear", clearCmd, ADMFLAG_CUSTOM1); //clears both, admins must have the "o" flag in their flags
	RegAdminCmd("vwpclearp", clearCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpclearprimary", clearCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpclears", clearCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpclearsecondary", clearCmd, ADMFLAG_CUSTOM1);

	RegAdminCmd("vwpsetp", setCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpsetprimary", setCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpsets", setCmd, ADMFLAG_CUSTOM1);
	RegAdminCmd("vwpsetsecondary", setCmd, ADMFLAG_CUSTOM1);
}

public onBoolConvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	//PrintToChatAll("cvar change: %s", newVal);
	if(StrEqual(newVal, "1")){SetConVarInt(cvar, 1);}
	if(StrEqual(newVal, "0")){SetConVarInt(cvar, 0);}
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(getVwpEnabled())
	{
		new client_id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(client_id);

		if(IsClientInGame(client) && (!IsFakeClient(client)))
		{
			SetClientCookie(client, receivedPrimaryCookie, "no");
			SetClientCookie(client, receivedSecondaryCookie, "no");
		}
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	currentPrimaryWeaponIndex = -1;
	currentSecondaryWeaponIndex = -1;
}

public Action:helpCmd(client, args)
{
	if(!getVwpEnabled())
	{
		PrintToChat(client, "[SM] Vote Weapon - Sorry, plugin is disabled.");
	}
	else
	{
		PrintToChat(client, "[SM] Vote Weapon by kumpu");
		PrintToChat(client, "!vwp or !voteweapon starts a vote for a weapon.");
		PrintToChat(client, "If the vote is successful, all players will have to use it.");
		PrintToChat(client, "You can disable Vote Weapon by selecting 'any weapon'");
		PrintToChat(client, "!vwplist prints a list of weapons.");

		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			PrintToChat(client, "!vwpclear sets both primary and secondary to any weapon.");
			PrintToChat(client, "!vwpclearp or !vwpclearprimary sets primary to any weapon.");
			PrintToChat(client, "!vwpclears or !vwpclearsecondary sets secondary to any weapon.");

			PrintToChat(client, "!vwpsetp <weapon> or !vwpsetprimary <weapon> sets primary.");
			PrintToChat(client, "!vwpsets <weapon> or !vwpsetsecondary <weapon> sets secondary.");
		}
	}
	return Plugin_Handled;
}

public Action:listCmd(client, args)
{
	if(!getVwpEnabled())
	{
		PrintToChat(client, "[SM] Vote Weapon - Sorry, plugin is disabled.");
	}
	else
	{
		PrintToChat(client, "[SM] Vote Weapon by kumpu");
		
		for(new i=0; i < sizeof(weaponGiveNameArray); i++){PrintToChat(client, "%i: %s", i, weaponGiveNameArray[i]);}
	}
	return Plugin_Handled;
}

public Action:clearCmd(client, args)
{
	if(!getVwpEnabled())
	{
		PrintToChat(client, "[SM] Vote Weapon - Sorry, plugin is disabled.");
	}
	else
	{
		new String:arg[128];
		GetCmdArg(0, arg, sizeof(arg));

		if(StrEqual(arg, "vwpclear"))
		{
			currentPrimaryWeaponIndex = -1;
			currentSecondaryWeaponIndex = -1;
			PrintToChatAll("[SM] Vote Weapon - primary and secondary set to any weapon");
		}
		if(StrEqual(arg, "vwpclearp") || StrEqual(arg, "vwpclearprimary"))
		{
			currentPrimaryWeaponIndex = -1;
			PrintToChatAll("[SM] Vote Weapon - primary set to any weapon");
		}
		if(StrEqual(arg, "vwpclears") || StrEqual(arg, "vwpclearsecondary"))
		{
			currentSecondaryWeaponIndex = -1;
			PrintToChatAll("[SM] Vote Weapon - secondary set to any weapon");
		}
	}

	return Plugin_Handled;
}

public Action:setCmd(client, args)
{
	if(!getVwpEnabled())
	{
		PrintToChat(client, "[SM] Vote Weapon - Sorry, plugin is disabled.");
	}
	else
	{
		new String:arg[128];
		GetCmdArg(0, arg, sizeof(arg));

		new String:weaponGiveName[128];
		GetCmdArg(1, weaponGiveName, sizeof(weaponGiveName));

		new weaponIndex = getWeaponIndexByGiveName(weaponGiveName);
		if(weaponIndex >= 0)
		{
			new String:weaponName[sizeof(weaponNameArray[])];
			weaponName = weaponNameArray[weaponIndex];

			new weaponClassIndex = getWeaponClassByIndex(weaponIndex);

			if(StrEqual(arg, "vwpsetp") || StrEqual(arg, "vwpsetprimary"))
			{
				if(weaponClassIndex > 0)
				{
					PrintToChatAll("[SM] Vote Weapon - changed primary weapon to: %s", weaponName)
					currentPrimaryWeaponIndex = weaponIndex;
				}
			}
			if(StrEqual(arg, "vwpsets") || StrEqual(arg, "vwpsetsecondary"))
			{
				if(weaponClassIndex == 0)
				{
					PrintToChatAll("[SM] Vote Weapon - changed secondary weapon to: %s", weaponName)
					currentSecondaryWeaponIndex = weaponIndex;
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] Vote Weapon - '%s' is not a valid weapon. See !vwplist for a list of weapons.");
		}
	}
	return Plugin_Handled;
}

public Action:startVoteCmd(client, args)
{
	if(!getVwpEnabled())
	{
		PrintToChat(client, "[SM] Vote Weapon - Sorry, plugin is disabled.");
	}
	else
	{
		if(voteInProgress){
			PrintToChat(client, "[SM] Vote Weapon - vote already in progress.");
		}
		else
		{
			new Handle:selectionMenu = CreateMenu(SelectionMenuHandler);
			SetMenuTitle(selectionMenu, "[SM] Weapon Vote by kumpu");
			if(getPrimaryEnabled()){AddMenuItem(selectionMenu, "primary", "Vote for a primary weapon");}
			if(getSecondaryEnabled()){AddMenuItem(selectionMenu, "secondary", "Vote for a secondary weapon");}
			SetMenuExitButton(selectionMenu, true);
			DisplayMenu(selectionMenu, client, 0);
		}
	}
	return Plugin_Handled;
}

setVote(client, bool:yes)
{
	if(IsClientInGame(client))
	{
		if(voteInProgress)
		{
			new String:answ[5];
			answ = "yes";
			if(!yes){answ = "no";}
			SetClientCookie(client, yesNoVoteCookie, answ);

			new String:name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("[SM] Weapon Vote - %s voted %s.", name, answ);
		}
		else
		{
			PrintToChat(client, "[SM] Vote Weapon - no vote in progress.");
		}
	}
}

public OnClientCookiesCached(client)
{	
	SetClientCookie(client, primaryWeaponVoteCookie, "");

	SetClientCookie(client, secondaryWeaponVoteCookie, "");

	SetClientCookie(client, yesNoVoteCookie, "");
}

findStringInArray(const String:stringToFind[], const String:stringArray[][], stringArraySize)
{
	new index = -1;

	for(new i=0; i < stringArraySize; i++)
	{
		if(StrEqual(stringToFind, stringArray[i], true))
		{
			index = i;
			i = stringArraySize;
		}	
	}

	return index;
}

getWeaponClassByName(const String:name[])
{
	return findStringInArray(name, classNameArray, sizeof(classNameArray));
}

getWeaponIndexByName(const String:name[])
{
	return findStringInArray(name, weaponNameArray, sizeof(weaponNameArray));
}

getWeaponIndexByGiveName(const String:name[])
{
	return findStringInArray(name, weaponGiveNameArray, sizeof(weaponGiveNameArray));
}

addMenuItemSafe(Handle:menu, const String:info[], const String:display[], style=ITEMDRAW_DEFAULT)
{
	if(!StrEqual(display, ""))
	{
		AddMenuItem(menu, info, display, style);
	}
}

Handle:buildMenuFromStringArray(MenuHandler:handler, String:title[], const String:stringArray[][], size, start=0, end=-1) //end == -1 -> whole rest
{
	if(start < 0){start = 0;}
	if(end == -1){end = size-1;}
	if(end > size){end = size-1;}

	new Handle:newmenu = CreateMenu(handler);
	SetMenuTitle(newmenu, title);

	for(new i=start; i <= end; i++)
	{
		addMenuItemSafe(newmenu, stringArray[i], stringArray[i]);
	}

	SetMenuExitButton(newmenu, true);

	return newmenu;
}

Handle:buildAndShowMenuFromStringArray(MenuHandler:handler1, String:title1[], const String:stringArray1[][], size1, start1=0, end1=-1, client) //end == -1 -> whole rest
{
	new Handle:menu1 = buildMenuFromStringArray(handler1, title1, stringArray1, size1, start1, end1);
	DisplayMenu(menu1, client, 0);
	return menu1;
}

public SelectionMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction_Select) //param1=client, param2=selected index
	{
		new String:info[50];
		
		GetMenuItem(menu, param2, info, sizeof(info));

		if(StrEqual(info, "primary", true))
		{
			new Handle:newmenu = buildMenuFromStringArray(SelectionMenuHandler, "[SM] Weapon Vote - Select primary class", classNameArray, sizeof(classNameArray), 1, 3);	
			addMenuItemSafe(newmenu, enabledWeaponNameArray[24], enabledWeaponNameArray[24]);
			addMenuItemSafe(newmenu, enabledWeaponNameArray[25], enabledWeaponNameArray[25]);
			DisplayMenu(newmenu, param1, 0);
		}
		if(StrEqual(info, "secondary", true))
		{
			new Handle:newmenu = buildMenuFromStringArray(SelectionMenuHandler, "[SM] Weapon Vote - Select secondary", enabledWeaponNameArray, sizeof(enabledWeaponNameArray), 0, 5);
			addMenuItemSafe(newmenu, enabledWeaponNameArray[26], enabledWeaponNameArray[26]);
			addMenuItemSafe(newmenu, enabledWeaponNameArray[27], enabledWeaponNameArray[27]);
			SetMenuPagination(newmenu, 0);
			DisplayMenu(newmenu, param1, 0);
		}

		new weaponClass = getWeaponClassByName(info);
		if(weaponClass == 1)
		{
			buildAndShowMenuFromStringArray(SelectionMenuHandler, "[SM] Weapon Vote - Shotguns", enabledWeaponNameArray, sizeof(enabledWeaponNameArray), 6, 7, param1);
		}
		if(weaponClass == 2)
		{
			buildAndShowMenuFromStringArray(SelectionMenuHandler, "[SM] Weapon Vote - Sub-Machineguns", enabledWeaponNameArray, sizeof(enabledWeaponNameArray), 8, 12, param1);
		}
		if(weaponClass == 3)
		{
			buildAndShowMenuFromStringArray(SelectionMenuHandler, "[SM] Weapon Vote - Rifles/MG", enabledWeaponNameArray, sizeof(enabledWeaponNameArray), 13, 23, param1);
		}

		new	weaponIndex = getWeaponIndexByName(info);
		//PrintToChatAll("weaponIndex: %i, info: %s, Ar[2]: %s", weaponIndex, info, weaponNameArray[2]);

		if(weaponIndex >= 0)
		{
			if(IsClientInGame(param1))
			{
				weaponClass = getWeaponClassByIndex(weaponIndex);
				if(weaponClass == 0)
				{				
					SetClientCookie(param1, secondaryWeaponVoteCookie, weaponGiveNameArray[weaponIndex]);					
				}else
				{
					//SetClientCookie(param1, primaryClassVoteCookie, classNameArray[weaponClass]);
					SetClientCookie(param1, primaryWeaponVoteCookie, weaponGiveNameArray[weaponIndex]);
				}
				triggerVote(param1, weaponClass, weaponIndex);
			}
		}
    }
}

public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction_Select) //param1=client, param2=selected index
	{
		new String:info[40];	
		GetMenuItem(menu, param2, info, sizeof(info));

		if(StrEqual(info, yesNoArray[0], true))//yes
		{
			//SetClientCookie(param1, yesNoVoteCookie, yesNoArray[0]);
			setVote(param1, true);
		}
		if(StrEqual(info, yesNoArray[1], true))//no
		{
			//SetClientCookie(param1, yesNoVoteCookie, yesNoArray[1]);
			setVote(param1, false);
		}
	}
	if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			new weaponClass = getWeaponClassByIndex(voteWeaponIndex);
			new String:prim[10] = "primary";
			if(weaponClass == 0)
			{
				prim = "secondary";
				currentSecondaryWeaponIndex = voteWeaponIndex;
				SetCookieAllClients(receivedSecondaryCookie, "no");
			}
			else
			{
				currentPrimaryWeaponIndex = voteWeaponIndex;
				SetCookieAllClients(receivedPrimaryCookie, "no");
			}
			new String:weaponName[sizeof(weaponNameArray[])];
			weaponName = weaponNameArray[voteWeaponIndex];
			while(ReplaceString(weaponName, sizeof(weaponName), "  ", " ")) { }

			PrintToChatAll("[SM] Vote Weapon - vote was accepted. %s weapon changed to: %s", prim, weaponName);
		}
		else
		{
			PrintToChatAll("[SM] Vote Weapon - vote was not accepted.");
		}
		voteInProgress = false;
	}
}

SetCookieAllClients(Handle:cookie, String:newValue[])
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && (!IsFakeClient(i)))
		{
			SetClientCookie(i, cookie, newValue);
		}	
	}
}

triggerVote(voteClient, weaponClass, weaponIndex)
{
	voteInProgress = true;
	//PrintToChatAll("client: %i, class: %i, index: %i", voteClient, weaponClass, weaponIndex);
	new String:name[MAX_NAME_LENGTH];
	GetClientName(voteClient, name, sizeof(name));

	new String:title[150];
	title = "[SM] Weapon Vote - ";
	StrCat(title, sizeof(title), name);

	new String:add[100];
	new String:prim[10] = "primary";
	if(weaponClass == 0)
	{
		add = " wants to change the secondary weapon to: ";
		prim = "secondary";
	}else
	{
		add = " wants to change the primary weapon to: ";
		StrCat(add, sizeof(add), classNameArray[weaponClass]);
		StrCat(add, sizeof(add), " - ");
	}
	voteWeaponIndex = weaponIndex;

	new String:weaponName[sizeof(weaponNameArray[])];
	weaponName = weaponNameArray[weaponIndex];
	//removeWhitespaces(weaponName, sizeof(weaponName));
	while(ReplaceString(weaponName, sizeof(weaponName), "  ", " ")) { }

	StrCat(add, sizeof(add), weaponName);
	StrCat(title, sizeof(title), add);

	new Handle:voteMenu = buildMenuFromStringArray(VoteMenuHandler, title, yesNoArray, sizeof(yesNoArray));

	PrintToChatAll("[SM] Weapon Vote - %s wants to change the %s weapon to: %s.", name, prim, weaponName);

	SetClientCookie(voteClient, yesNoVoteCookie, yesNoArray[0]);
	new clients[MaxClients];
	new clientsSize = 0;

	for (new i=1; i<=MaxClients; i++)
	{
		//if ((voteClient != i) && IsClientInGame(i))
		if(IsClientInGame(i) && (!IsFakeClient(i)))
		{
			SetClientCookie(i, yesNoVoteCookie, yesNoArray[1]);
			clients[clientsSize++] = i;
		}	
	}
	if(clientsSize > 0){VoteMenu(voteMenu, clients, clientsSize, 30);}
}
 
public Action:Timer_manageWeapons(Handle:timer)
{
	if(getVwpEnabled())
	{
		if((currentPrimaryWeaponIndex >= 0) || (currentSecondaryWeaponIndex >= 0))
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(IsFakeClient(i) && getIgnoreBots()){continue;}
					if(IsPlayerAlive(i))
					{
						if((currentPrimaryWeaponIndex >= 0) && (currentPrimaryWeaponIndex != 25))//any primary - disabled
						{
							checkWeaponSlot(i, 0, currentPrimaryWeaponIndex);
						}
						if((currentSecondaryWeaponIndex >= 0) && (currentSecondaryWeaponIndex != 27))//any secondary -disabled
						{
							checkWeaponSlot(i, 1, currentSecondaryWeaponIndex);
						}
					}
				}	
			}
	 	}
	}

	return Plugin_Continue;
}

checkWeaponSlot(client, slot, vwp_weaponIndex)
{
	//PrintToChatAll("curWeaponIndex: %i, slot: %i, vwp_weaponIndex: %i ", curWeaponIndex, slot, vwp_weaponIndex);

	new bool:newWeapon = false;
	new String:prim[10] = "primary";
	if(slot == 0){
		new String:recPrimary[4];
		GetClientCookie(client, receivedPrimaryCookie, recPrimary, 4);
		if(StrEqual(recPrimary, "no"))
		{
			SetClientCookie(client, receivedPrimaryCookie, "yes");
			if(vwp_weaponIndex < 24){newWeapon = true;}
		}
	}
	if(slot == 1){
		new String:recSecondary[4];
		GetClientCookie(client, receivedSecondaryCookie, recSecondary, 4);
		if(StrEqual(recSecondary, "no"))
		{
			prim = "secondary";
			SetClientCookie(client, receivedSecondaryCookie, "yes");
			if(vwp_weaponIndex < 24){newWeapon = true;}
		}
	}

	new cssWeaponEntity = GetPlayerWeaponSlot(client, slot);
	if(cssWeaponEntity >= 0)
	{
		new String:curCssWeaponGiveName[32];
		GetEntityClassname(cssWeaponEntity, curCssWeaponGiveName, 32);
		ReplaceString(curCssWeaponGiveName, sizeof(curCssWeaponGiveName), "weapon_", "");

		if(!StrEqual(curCssWeaponGiveName, weaponGiveNameArray[vwp_weaponIndex]))
		{
			RemovePlayerItem(client, cssWeaponEntity);

			new String:vwpWeaponName[sizeof(weaponNameArray[])];
			vwpWeaponName = weaponNameArray[vwp_weaponIndex];
			while(ReplaceString(vwpWeaponName, sizeof(vwpWeaponName), "  ", " ")) { }
			PrintToChat(client, "[SM] Vote Weapon - removed %s weapon - current %s is %s. !vwphelp for help.", prim, prim, vwpWeaponName);		
		}
	}

	if(newWeapon){giveWeapon(client, vwp_weaponIndex, prim);}
}

giveWeapon(client, weaponIndex, String:prim[10])
{
	new String:weaponName[sizeof(weaponNameArray[])];
	weaponName = weaponNameArray[weaponIndex];
	while(ReplaceString(weaponName, sizeof(weaponName), "  ", " ")) { }
	PrintToChat(client, "[SM] Vote Weapon - received %s weapon %s. !vwphelp for help.", prim, weaponName);

	new String:weaponGiveName[sizeof(weaponGiveNameArray)];
	weaponGiveName = weaponGiveNameArray[weaponIndex];

	new String:give[20] = "weapon_";
	StrCat(give,sizeof(give),weaponGiveName);
	
	GivePlayerItem(client,give);
}

setEnabledWeapons()
{
	for(new i = 1; i < sizeof(weaponGiveNameArray); i++)
	{
		strcopy(enabledWeaponNameArray[i], sizeof(enabledWeaponNameArray[]), weaponNameArray[i]);	
	}

	new String:path[PLATFORM_MAX_PATH], String:line[18], Handle:fileHandle, weaponIndex;
	path = "cfg\\sourcemod\\weaponVote_disabledWeapons.txt";

	if(FileExists(path))
	{
		fileHandle = OpenFile(path,"r"); // Opens addons/sourcemod/blank.txt to read from (and only reading)

		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
		{
			TrimString(line);
			weaponIndex = getWeaponIndexByGiveName(line);
			//PrintToServer("%i, /%s/",weaponIndex,line);

			if(weaponIndex >= 0)
			{
				strcopy(enabledWeaponNameArray[weaponIndex], sizeof(enabledWeaponNameArray[]), "");
			}
		}
	}
	else
	{
		fileHandle = OpenFile(path,"w"); //auto create
	}
	CloseHandle(fileHandle);
}
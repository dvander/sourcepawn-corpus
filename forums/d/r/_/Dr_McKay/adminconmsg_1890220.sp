#include <sourcemod>
#include <morecolors>

#undef REQUIRE_PLUGIN
#include <sourceirc>

#define PLUGIN_VERSION "1.6.0-sourceirc"

new Handle:cvarEnabled;
new Handle:cvarChat;
new Handle:cvarColor;
new Handle:cvarCenter;
new Handle:cvarHint;
new Handle:cvarHud;
new Handle:cvarServer;
new Handle:cvarSourceIRC;
new Handle:cvarSpecial;
new Handle:Version;

new bool:gameTF2 = false;
new bool:gameHL2MP = false;
new String:g_hSpecial[128];

public Plugin:myinfo =
{
	name = "Admin Connect Message (Extended)",
	author = "ReFlexPoison",
	description = "Post connecting admins and special players through hud and say commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183966"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	MarkNativeAsOptional("IRC_MsgFlaggedChannels");
	MarkNativeAsOptional("GetUserMessageType");
	return APLRes_Success;
}

public OnPluginStart()
{
	Version = CreateConVar("sm_adminconmsg_version", PLUGIN_VERSION, "Admin Connect Message (Extended) Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	decl String:game[64];
	GetGameFolderName(game, sizeof(game));

	gameTF2 = StrEqual(game, "tf");
	gameHL2MP = StrEqual(game, "hl2mp");

	cvarEnabled = CreateConVar("sm_adminconmsg_enabled", "1", "Enable Admin Connect Message\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarChat = CreateConVar("sm_adminconmsg_chat", "1", "Post admin connect notification in chat\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarColor = CreateConVar("sm_adminconmsg_color", "0", "Admin connect chat color (See case values)", FCVAR_NONE, true, 0.0, true, 153.0);
	cvarCenter = CreateConVar("sm_adminconmsg_center", "1", "Post admin connect notification in center\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHint = CreateConVar("sm_adminconmsg_hint", "0", "Post admin connect notification in hint\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarServer = CreateConVar("sm_adminconmsg_server", "1", "Post admin connect notification in server console\n0 = Disabled\n1 = Enabled");
	cvarSourceIRC = CreateConVar("sm_adminconmsg_sourceirc", "1", "Post admin connect notification in SourceIRC\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSpecial = CreateConVar("sm_adminconmsg_special", "Donor", "What to call special players", FCVAR_NONE);
	if(gameTF2 || gameHL2MP) cvarHud = CreateConVar("sm_adminconmsg_hud", "0", "Post admin connect notification in hud\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);

	HookConVarChange(cvarSpecial, CVarChange);
	HookConVarChange(Version, CVarChange);

	AutoExecConfig(true, "plugin.adminconmsg");
}

public OnConfigsExecuted()
{
	GetConVarString(cvarSpecial, g_hSpecial, sizeof(g_hSpecial));
}

public CVarChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == cvarSpecial) GetConVarString(convar, g_hSpecial, sizeof(g_hSpecial));
	else if(convar == Version) SetConVarString(Version, PLUGIN_VERSION)
}

public OnClientPostAdminCheck(client)
{
	if(!GetConVarBool(cvarEnabled)) return;

	if(CheckCommandAccess(client, "adminconmsg_admin_flag", ADMFLAG_GENERIC) || CheckCommandAccess(client, "adminconmsg_donator_flag", ADMFLAG_RESERVATION))
	{
		decl String:type[10];
		type[0] = '\0';

		if(CheckCommandAccess(client, "adminconmsg_admin_flag", ADMFLAG_GENERIC)) Format(type, sizeof(type), "Admin");
		else Format(type, sizeof(type), (g_hSpecial));

		if(GetConVarBool(cvarChat))
		{
			switch (GetConVarInt(cvarColor))
			{
				case 0: PrintToChatAll("\x01%s %N Connected", type, client);
				case 1: PrintToChatAll("\x02%s %N Connected", type, client);
				case 2: PrintToChatAll("\x03%s %N Connected", type, client);
				case 3: PrintToChatAll("\x04%s %N Connected", type, client);
				case 4: PrintToChatAll("\x05%s %N Connected", type, client);
				//Not supported for all games:
				case 5: CPrintToChatAll("{aliceblue}%s %N Connected", type, client);
				case 6: CPrintToChatAll("{antiquewhite}%s %N Connected", type, client);
				case 7: CPrintToChatAll("{aqua}%s %N Connected", type, client);
				case 8: CPrintToChatAll("{aquamarine}%s %N Connected", type, client);
				case 9: CPrintToChatAll("{azure}%s %N Connected", type, client);
				case 10: CPrintToChatAll("{beige}%s %N Connected", type, client);
				case 11: CPrintToChatAll("{bisque}%s %N Connected", type, client);
				case 12: CPrintToChatAll("{black}%s %N Connected", type, client);
				case 13: CPrintToChatAll("{blanchedalmond}%s %N Connected", type, client);
				case 14: CPrintToChatAll("{blue}%s %N Connected", type, client);
				case 15: CPrintToChatAll("{blueviolet}%s %N Connected", type, client);
				case 16: CPrintToChatAll("{brown}%s %N Connected", type, client);
				case 17: CPrintToChatAll("{burlywood}%s %N Connected", type, client);
				case 18: CPrintToChatAll("{cadetblue}%s %N Connected", type, client);
				case 19: CPrintToChatAll("{chartreuse}%s %N Connected", type, client);
				case 20: CPrintToChatAll("{chocolate}%s %N Connected", type, client);
				case 21: CPrintToChatAll("{coral}%s %N Connected", type, client);
				case 22: CPrintToChatAll("{cornflowerblue}%s %N Connected", type, client);
				case 23: CPrintToChatAll("{cornsilk}%s %N Connected", type, client);
				case 24: CPrintToChatAll("{crimson}%s %N Connected", type, client);
				case 25: CPrintToChatAll("{cyan}%s %N Connected", type, client);
				case 26: CPrintToChatAll("{darkblue}%s %N Connected", type, client);
				case 27: CPrintToChatAll("{darkcyan}%s %N Connected", type, client);
				case 28: CPrintToChatAll("{darkgoldenrod}%s %N Connected", type, client);
				case 29: CPrintToChatAll("{darkgray}%s %N Connected", type, client);
				case 30: CPrintToChatAll("{darkgrey}%s %N Connected", type, client);
				case 31: CPrintToChatAll("{darkgreen}%s %N Connected", type, client);
				case 32: CPrintToChatAll("{darkkhaki}%s %N Connected", type, client);
				case 33: CPrintToChatAll("{darkmagenta}%s %N Connected", type, client);
				case 34: CPrintToChatAll("{darkolivegreen}%s %N Connected", type, client);
				case 35: CPrintToChatAll("{darkorange}%s %N Connected", type, client);
				case 36: CPrintToChatAll("{darkorchid}%s %N Connected", type, client);
				case 37: CPrintToChatAll("{darkred}%s %N Connected", type, client);
				case 38: CPrintToChatAll("{darksalmon}%s %N Connected", type, client);
				case 39: CPrintToChatAll("{darkseagreen}%s %N Connected", type, client);
				case 40: CPrintToChatAll("{darkslateblue}%s %N Connected", type, client);
				case 41: CPrintToChatAll("{darkslategray}%s %N Connected", type, client);
				case 42: CPrintToChatAll("{darkslategrey}%s %N Connected", type, client);
				case 43: CPrintToChatAll("{darkturquoise}%s %N Connected", type, client);
				case 44: CPrintToChatAll("{darkviolet}%s %N Connected", type, client);
				case 45: CPrintToChatAll("{deeppink}%s %N Connected", type, client);
				case 46: CPrintToChatAll("{deepskyblue}%s %N Connected", type, client);
				case 47: CPrintToChatAll("{dimgray}%s %N Connected", type, client);
				case 48: CPrintToChatAll("{dimgrey}%s %N Connected", type, client);
				case 49: CPrintToChatAll("{dodgerblue}%s %N Connected", type, client);
				case 50: CPrintToChatAll("{firebrick}%s %N Connected", type, client);
				case 51: CPrintToChatAll("{floralwhite}%s %N Connected", type, client);
				case 52: CPrintToChatAll("{forestgreen}%s %N Connected", type, client);
				case 53: CPrintToChatAll("{fuchsia}%s %N Connected", type, client);
				case 54: CPrintToChatAll("{fullblue}%s %N Connected", type, client);
				case 55: CPrintToChatAll("{fullred}%s %N Connected", type, client);
				case 56: CPrintToChatAll("{gainsboro}%s %N Connected", type, client);
				case 57: CPrintToChatAll("{ghostwhite}%s %N Connected", type, client);
				case 58: CPrintToChatAll("{gold}%s %N Connected", type, client);
				case 59: CPrintToChatAll("{goldenrod}%s %N Connected", type, client);
				case 60: CPrintToChatAll("{gray}%s %N Connected", type, client);
				case 61: CPrintToChatAll("{grey}%s %N Connected", type, client);
				case 62: CPrintToChatAll("{green}%s %N Connected", type, client);
				case 63: CPrintToChatAll("{greenyellow}%s %N Connected", type, client);
				case 64: CPrintToChatAll("{honeydew}%s %N Connected", type, client);
				case 65: CPrintToChatAll("{hotpink}%s %N Connected", type, client);
				case 66: CPrintToChatAll("{indianred}%s %N Connected", type, client);
				case 67: CPrintToChatAll("{indigo}%s %N Connected", type, client);
				case 68: CPrintToChatAll("{ivory}%s %N Connected", type, client);
				case 69: CPrintToChatAll("{khaki}%s %N Connected", type, client);
				case 70: CPrintToChatAll("{lavender}%s %N Connected", type, client);
				case 71: CPrintToChatAll("{lavenderblush}%s %N Connected", type, client);
				case 72: CPrintToChatAll("{lawngreen}%s %N Connected", type, client);
				case 73: CPrintToChatAll("{lemonchiffon}%s %N Connected", type, client);
				case 74: CPrintToChatAll("{lightblue}%s %N Connected", type, client);
				case 75: CPrintToChatAll("{lightcoral}%s %N Connected", type, client);
				case 76: CPrintToChatAll("{lightcyan}%s %N Connected", type, client);
				case 77: CPrintToChatAll("{lightgoldenrodyellow}%s %N Connected", type, client);
				case 78: CPrintToChatAll("{lightgray}%s %N Connected", type, client);
				case 79: CPrintToChatAll("{lightgrey}%s %N Connected", type, client);
				case 80: CPrintToChatAll("{lightgreen}%s %N Connected", type, client);
				case 81: CPrintToChatAll("{lightpink}%s %N Connected", type, client);
				case 82: CPrintToChatAll("{lightsalmon}%s %N Connected", type, client);
				case 83: CPrintToChatAll("{lightseagreen}%s %N Connected", type, client);
				case 84: CPrintToChatAll("{lightskyblue}%s %N Connected", type, client);
				case 85: CPrintToChatAll("{lightslategray}%s %N Connected", type, client);
				case 86: CPrintToChatAll("{lightslategrey}%s %N Connected", type, client);
				case 87: CPrintToChatAll("{lightsteelblue}%s %N Connected", type, client);
				case 88: CPrintToChatAll("{lightyellow}%s %N Connected", type, client);
				case 89: CPrintToChatAll("{lime}%s %N Connected", type, client);
				case 90: CPrintToChatAll("{limegreen}%s %N Connected", type, client);
				case 91: CPrintToChatAll("{linen}%s %N Connected", type, client);
				case 92: CPrintToChatAll("{magenta}%s %N Connected", type, client);
				case 93: CPrintToChatAll("{maroon}%s %N Connected", type, client);
				case 94: CPrintToChatAll("{mediumaquamarine}%s %N Connected", type, client);
				case 95: CPrintToChatAll("{mediumblue}%s %N Connected", type, client);
				case 96: CPrintToChatAll("{mediumorchid}%s %N Connected", type, client);
				case 97: CPrintToChatAll("{mediumpurple}%s %N Connected", type, client);
				case 98: CPrintToChatAll("{mediumseagreen}%s %N Connected", type, client);
				case 99: CPrintToChatAll("{mediumslateblue}%s %N Connected", type, client);
				case 100: CPrintToChatAll("{mediumspringgreen}%s %N Connected", type, client);
				case 101: CPrintToChatAll("{mediumturquoise}%s %N Connected", type, client);
				case 102: CPrintToChatAll("{mediumvioletred}%s %N Connected", type, client);
				case 103: CPrintToChatAll("{midnightblue}%s %N Connected", type, client);
				case 104: CPrintToChatAll("{mintcream}%s %N Connected", type, client);
				case 105: CPrintToChatAll("{mistyrose}%s %N Connected", type, client);
				case 106: CPrintToChatAll("{moccasin}%s %N Connected", type, client);
				case 107: CPrintToChatAll("{navajowhite}%s %N Connected", type, client);
				case 108: CPrintToChatAll("{navy}%s %N Connected", type, client);
				case 109: CPrintToChatAll("{oldlace}%s %N Connected", type, client);
				case 110: CPrintToChatAll("{olive}%s %N Connected", type, client);
				case 111: CPrintToChatAll("{olivedrab}%s %N Connected", type, client);
				case 112: CPrintToChatAll("{orange}%s %N Connected", type, client);
				case 113: CPrintToChatAll("{orangered}%s %N Connected", type, client);
				case 114: CPrintToChatAll("{orchid}%s %N Connected", type, client);
				case 115: CPrintToChatAll("{palegoldenrod}%s %N Connected", type, client);
				case 116: CPrintToChatAll("{palegreen}%s %N Connected", type, client);
				case 117: CPrintToChatAll("{paleturquoise}%s %N Connected", type, client);
				case 118: CPrintToChatAll("{palevioletred}%s %N Connected", type, client);
				case 119: CPrintToChatAll("{papayawhip}%s %N Connected", type, client);
				case 120: CPrintToChatAll("{peachpuff}%s %N Connected", type, client);
				case 121: CPrintToChatAll("{peru}%s %N Connected", type, client);
				case 122: CPrintToChatAll("{pink}%s %N Connected", type, client);
				case 123: CPrintToChatAll("{plum}%s %N Connected", type, client);
				case 124: CPrintToChatAll("{powderblue}%s %N Connected", type, client);
				case 125: CPrintToChatAll("{purple}%s %N Connected", type, client);
				case 126: CPrintToChatAll("{red}%s %N Connected", type, client);
				case 127: CPrintToChatAll("{rosybrown}%s %N Connected", type, client);
				case 128: CPrintToChatAll("{royalblue}%s %N Connected", type, client);
				case 129: CPrintToChatAll("{saddlebrown}%s %N Connected", type, client);
				case 130: CPrintToChatAll("{salmon}%s %N Connected", type, client);
				case 131: CPrintToChatAll("{sandybrown}%s %N Connected", type, client);
				case 132: CPrintToChatAll("{seagreen}%s %N Connected", type, client);
				case 133: CPrintToChatAll("{seashell}%s %N Connected", type, client);
				case 134: CPrintToChatAll("{sienna}%s %N Connected", type, client);
				case 135: CPrintToChatAll("{silver}%s %N Connected", type, client);
				case 136: CPrintToChatAll("{skyblue}%s %N Connected", type, client);
				case 137: CPrintToChatAll("{slateblue}%s %N Connected", type, client);
				case 138: CPrintToChatAll("{slategray}%s %N Connected", type, client);
				case 139: CPrintToChatAll("{slategrey}%s %N Connected", type, client);
				case 140: CPrintToChatAll("{snow}%s %N Connected", type, client);
				case 141: CPrintToChatAll("{springgreen}%s %N Connected", type, client);
				case 142: CPrintToChatAll("{steelblue}%s %N Connected", type, client);
				case 143: CPrintToChatAll("{tan}%s %N Connected", type, client);
				case 144: CPrintToChatAll("{teal}%s %N Connected", type, client);
				case 145: CPrintToChatAll("{thistle}%s %N Connected", type, client);
				case 146: CPrintToChatAll("{tomato}%s %N Connected", type, client);
				case 147: CPrintToChatAll("{turquoise}%s %N Connected", type, client);
				case 148: CPrintToChatAll("{violet}%s %N Connected", type, client);
				case 149: CPrintToChatAll("{wheat}%s %N Connected", type, client);
				case 150: CPrintToChatAll("{white}%s %N Connected", type, client);
				case 151: CPrintToChatAll("{whitesmoke}%s %N Connected", type, client);
				case 152: CPrintToChatAll("{yellow}%s %N Connected", type, client);
				case 153: CPrintToChatAll("{yellowgreen}%s %N Connected", type, client);
			}
		}
		if(GetConVarBool(cvarCenter)) PrintCenterTextAll("%s %N Connected", type, client);
		if((gameTF2 || gameHL2MP) && GetConVarBool(cvarHud))
		{
			SetHudTextParams(-1.0, 0.3, 7.5, 255, 255, 255, 255)
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i)) ShowHudText(i, -1, "%s %N Connected", type, client);
			}
		}
		if(GetConVarBool(cvarHint)) PrintHintTextToAll("%s %N Connected", type, client);
		if(GetConVarBool(cvarServer)) PrintToServer("%s %N Connected", type, client);
		if(GetConVarBool(cvarSourceIRC)) IRC_MsgFlaggedChannels("ticket", "%s %N Connected", type, client);
	}
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if((replaycheck) && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}
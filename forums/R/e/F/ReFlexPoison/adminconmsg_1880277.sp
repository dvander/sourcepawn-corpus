#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <morecolors>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.6.1"

#define	dChat					(1 << 0)	//	1
#define	dCenter					(1 << 1)	//	2
#define	dHint					(1 << 2)	//	4
#define	dServer					(1 << 3)	//	8
#define	dHud					(1 << 4)	//	16

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarColor;
new Handle:cvarSpecial;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new g_iColor;
new bool:g_bGameTF2;
new bool:g_bGameHL2MP;
new String:g_strSpecial[255];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Admin Connect Message (Extended)",
	author = "ReFlexPoison",
	description = "Post connecting admins and special players through hud and say commands",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183966"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_adminconmsg_version", PLUGIN_VERSION, "Admin Connect Message (Extended) Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	decl String:strGame[16];
	GetGameFolderName(strGame, sizeof(strGame));
	g_bGameTF2 = StrEqual(strGame, "tf");
	g_bGameHL2MP = StrEqual(strGame, "hl2mp");

	cvarEnabled = CreateConVar("sm_adminconmsg_enabled", "31", "Enable Admin Connect Message (Extended) (Add up values)\n0 = Disabled\n1 = Chat\n2 = Center\n4 = Hint\n8 = Server\n16 = Hud", FCVAR_NONE, true, 0.0, true, 31.0);
	g_iEnabled = GetConVarInt(cvarEnabled);

	cvarColor = CreateConVar("sm_adminconmsg_color", "0", "Admin connect chat color (See case values)", FCVAR_NONE, true, 0.0, true, 165.0);
	g_iColor = GetConVarInt(cvarColor);

	cvarSpecial = CreateConVar("sm_adminconmsg_special", "Donor", "What to call special players (Leave blank to disable notifications of special players)", FCVAR_NONE);
	GetConVarString(cvarSpecial, g_strSpecial, sizeof(g_strSpecial));

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarColor, CVarChange);
	HookConVarChange(cvarSpecial, CVarChange);

	AutoExecConfig(true, "plugin.adminconmsg");
}

public CVarChange(Handle:hConvar, const String:oldVal[], const String:newVal[])
{
	if(hConvar == cvarEnabled)
		g_iEnabled = GetConVarInt(cvarEnabled);
	if(hConvar == cvarColor)
		g_iColor = GetConVarInt(cvarColor);
	if(hConvar == cvarSpecial)
		GetConVarString(cvarSpecial, g_strSpecial, sizeof(g_strSpecial));
}

public OnClientPostAdminCheck(iClient)
{
	if(g_iEnabled <= 0)
		return;

	new bool:bAdmin = CheckCommandAccess(iClient, "adminconmsg_admin_flag", ADMFLAG_GENERIC);
	new bool:bSpecial = CheckCommandAccess(iClient, "adminconmsg_donator_flag", ADMFLAG_RESERVATION);
	if(bAdmin || (g_strSpecial[0] != '\0' && bSpecial))
	{
		decl String:strType[255];
		if(bAdmin)
			Format(strType, sizeof(strType), "Admin");
		else
			Format(strType, sizeof(strType), g_strSpecial);

		if(g_iEnabled & dChat)
		{
			switch(g_iColor)
			{
				case 0: PrintToChatAll("\x01%s %N Connected", strType, iClient);
				case 1: PrintToChatAll("\x02%s %N Connected", strType, iClient);
				case 2: PrintToChatAll("\x03%s %N Connected", strType, iClient);
				case 3: PrintToChatAll("\x04%s %N Connected", strType, iClient);
				case 4: PrintToChatAll("\x05%s %N Connected", strType, iClient);
				//Not supported for all games:
				case 5: CPrintToChatAll("{aliceblue}%s %N Connected", strType, iClient);
				case 6: CPrintToChatAll("{allies}%s %N Connected", strType, iClient); // same as Allies team in DoD:S
				case 7: CPrintToChatAll("{antiquewhite}%s %N Connected", strType, iClient);
				case 8: CPrintToChatAll("{aqua}%s %N Connected", strType, iClient);
				case 9: CPrintToChatAll("{aquamarine}%s %N Connected", strType, iClient);
				case 10: CPrintToChatAll("{axis}%s %N Connected", strType, iClient); // same as Axis team in DoD:S
				case 11: CPrintToChatAll("{azure}%s %N Connected", strType, iClient);
				case 12: CPrintToChatAll("{beige}%s %N Connected", strType, iClient);
				case 13: CPrintToChatAll("{bisque}%s %N Connected", strType, iClient);
				case 14: CPrintToChatAll("{black}%s %N Connected", strType, iClient);
				case 15: CPrintToChatAll("{blanchedalmond}%s %N Connected", strType, iClient);
				case 16: CPrintToChatAll("{blue}%s %N Connected", strType, iClient); // same as BLU/Counter-Terrorist team color
				case 17: CPrintToChatAll("{blueviolet}%s %N Connected", strType, iClient);
				case 18: CPrintToChatAll("{brown}%s %N Connected", strType, iClient);
				case 19: CPrintToChatAll("{burlywood}%s %N Connected", strType, iClient);
				case 20: CPrintToChatAll("{cadetblue}%s %N Connected", strType, iClient);
				case 21: CPrintToChatAll("{chartreuse}%s %N Connected", strType, iClient);
				case 22: CPrintToChatAll("{chocolate}%s %N Connected", strType, iClient);
				case 23: CPrintToChatAll("{community}%s %N Connected", strType, iClient); // same as Community item quality in TF2
				case 24: CPrintToChatAll("{coral}%s %N Connected", strType, iClient);
				case 25: CPrintToChatAll("{cornflowerblue}%s %N Connected", strType, iClient);
				case 26: CPrintToChatAll("{cornsilk}%s %N Connected", strType, iClient);
				case 27: CPrintToChatAll("{crimson}%s %N Connected", strType, iClient);
				case 28: CPrintToChatAll("{cyan}%s %N Connected", strType, iClient);
				case 29: CPrintToChatAll("{darkblue}%s %N Connected", strType, iClient);
				case 30: CPrintToChatAll("{darkcyan}%s %N Connected", strType, iClient);
				case 31: CPrintToChatAll("{darkgoldenrod}%s %N Connected", strType, iClient);
				case 32: CPrintToChatAll("{darkgray}%s %N Connected", strType, iClient);
				case 33: CPrintToChatAll("{darkgrey}%s %N Connected", strType, iClient);
				case 34: CPrintToChatAll("{darkgreen}%s %N Connected", strType, iClient);
				case 35: CPrintToChatAll("{darkkhaki}%s %N Connected", strType, iClient);
				case 36: CPrintToChatAll("{darkmagenta}%s %N Connected", strType, iClient);
				case 37: CPrintToChatAll("{darkolivegreen}%s %N Connected", strType, iClient);
				case 38: CPrintToChatAll("{darkorange}%s %N Connected", strType, iClient);
				case 39: CPrintToChatAll("{darkorchid}%s %N Connected", strType, iClient);
				case 40: CPrintToChatAll("{darkred}%s %N Connected", strType, iClient);
				case 41: CPrintToChatAll("{darksalmon}%s %N Connected", strType, iClient);
				case 42: CPrintToChatAll("{darkseagreen}%s %N Connected", strType, iClient);
				case 43: CPrintToChatAll("{darkslateblue}%s %N Connected", strType, iClient);
				case 44: CPrintToChatAll("{darkslategray}%s %N Connected", strType, iClient);
				case 45: CPrintToChatAll("{darkslategrey}%s %N Connected", strType, iClient);
				case 46: CPrintToChatAll("{darkturquoise}%s %N Connected", strType, iClient);
				case 47: CPrintToChatAll("{darkviolet}%s %N Connected", strType, iClient);
				case 48: CPrintToChatAll("{deeppink}%s %N Connected", strType, iClient);
				case 49: CPrintToChatAll("{deepskyblue}%s %N Connected", strType, iClient);
				case 50: CPrintToChatAll("{dimgray}%s %N Connected", strType, iClient);
				case 51: CPrintToChatAll("{dimgrey}%s %N Connected", strType, iClient);
				case 52: CPrintToChatAll("{dodgerblue}%s %N Connected", strType, iClient);
				case 53: CPrintToChatAll("{firebrick}%s %N Connected", strType, iClient);
				case 54: CPrintToChatAll("{floralwhite}%s %N Connected", strType, iClient);
				case 55: CPrintToChatAll("{forestgreen}%s %N Connected", strType, iClient);
				case 56: CPrintToChatAll("{fuchsia}%s %N Connected", strType, iClient);
				case 57: CPrintToChatAll("{fullblue}%s %N Connected", strType, iClient);
				case 58: CPrintToChatAll("{fullred}%s %N Connected", strType, iClient);
				case 59: CPrintToChatAll("{gainsboro}%s %N Connected", strType, iClient);
				case 60: CPrintToChatAll("{genuine}%s %N Connected", strType, iClient); // same as Genuine item quality in TF2
				case 61: CPrintToChatAll("{ghostwhite}%s %N Connected", strType, iClient);
				case 62: CPrintToChatAll("{gold}%s %N Connected", strType, iClient);
				case 63: CPrintToChatAll("{goldenrod}%s %N Connected", strType, iClient);
				case 64: CPrintToChatAll("{gray}%s %N Connected", strType, iClient); // same as spectator team color
				case 65: CPrintToChatAll("{grey}%s %N Connected", strType, iClient);
				case 66: CPrintToChatAll("{green}%s %N Connected", strType, iClient);
				case 67: CPrintToChatAll("{greenyellow}%s %N Connected", strType, iClient);
				case 68: CPrintToChatAll("{haunted}%s %N Connected", strType, iClient); // same as Haunted item quality in TF2
				case 69: CPrintToChatAll("{honeydew}%s %N Connected", strType, iClient);
				case 70: CPrintToChatAll("{hotpink}%s %N Connected", strType, iClient);
				case 71: CPrintToChatAll("{indianred}%s %N Connected", strType, iClient);
				case 72: CPrintToChatAll("{indigo}%s %N Connected", strType, iClient);
				case 73: CPrintToChatAll("{ivory}%s %N Connected", strType, iClient);
				case 74: CPrintToChatAll("{khaki}%s %N Connected", strType, iClient);
				case 75: CPrintToChatAll("{lavender}%s %N Connected", strType, iClient);
				case 76: CPrintToChatAll("{lavenderblush}%s %N Connected", strType, iClient);
				case 77: CPrintToChatAll("{lawngreen}%s %N Connected", strType, iClient);
				case 78: CPrintToChatAll("{lemonchiffon}%s %N Connected", strType, iClient);
				case 79: CPrintToChatAll("{lightblue}%s %N Connected", strType, iClient);
				case 80: CPrintToChatAll("{lightcoral}%s %N Connected", strType, iClient);
				case 81: CPrintToChatAll("{lightcyan}%s %N Connected", strType, iClient);
				case 82: CPrintToChatAll("{lightgoldenrodyellow}%s %N Connected", strType, iClient);
				case 83: CPrintToChatAll("{lightgray}%s %N Connected", strType, iClient);
				case 84: CPrintToChatAll("{lightgrey}%s %N Connected", strType, iClient);
				case 85: CPrintToChatAll("{lightgreen}%s %N Connected", strType, iClient);
				case 86: CPrintToChatAll("{lightpink}%s %N Connected", strType, iClient);
				case 87: CPrintToChatAll("{lightsalmon}%s %N Connected", strType, iClient);
				case 88: CPrintToChatAll("{lightseagreen}%s %N Connected", strType, iClient);
				case 89: CPrintToChatAll("{lightskyblue}%s %N Connected", strType, iClient);
				case 90: CPrintToChatAll("{lightslategray}%s %N Connected", strType, iClient);
				case 91: CPrintToChatAll("{lightslategrey}%s %N Connected", strType, iClient);
				case 92: CPrintToChatAll("{lightsteelblue}%s %N Connected", strType, iClient);
				case 93: CPrintToChatAll("{lightyellow}%s %N Connected", strType, iClient);
				case 94: CPrintToChatAll("{lime}%s %N Connected", strType, iClient);
				case 95: CPrintToChatAll("{limegreen}%s %N Connected", strType, iClient);
				case 96: CPrintToChatAll("{linen}%s %N Connected", strType, iClient);
				case 97: CPrintToChatAll("{magenta}%s %N Connected", strType, iClient);
				case 98: CPrintToChatAll("{maroon}%s %N Connected", strType, iClient);
				case 99: CPrintToChatAll("{mediumaquamarine}%s %N Connected", strType, iClient);
				case 100: CPrintToChatAll("{mediumblue}%s %N Connected", strType, iClient);
				case 101: CPrintToChatAll("{mediumorchid}%s %N Connected", strType, iClient);
				case 102: CPrintToChatAll("{mediumpurple}%s %N Connected", strType, iClient);
				case 103: CPrintToChatAll("{mediumseagreen}%s %N Connected", strType, iClient);
				case 104: CPrintToChatAll("{mediumslateblue}%s %N Connected", strType, iClient);
				case 105: CPrintToChatAll("{mediumspringgreen}%s %N Connected", strType, iClient);
				case 106: CPrintToChatAll("{mediumturquoise}%s %N Connected", strType, iClient);
				case 107: CPrintToChatAll("{mediumvioletred}%s %N Connected", strType, iClient);
				case 108: CPrintToChatAll("{midnightblue}%s %N Connected", strType, iClient);
				case 109: CPrintToChatAll("{mintcream}%s %N Connected", strType, iClient);
				case 110: CPrintToChatAll("{mistyrose}%s %N Connected", strType, iClient);
				case 111: CPrintToChatAll("{moccasin}%s %N Connected", strType, iClient);
				case 112: CPrintToChatAll("{navajowhite}%s %N Connected", strType, iClient);
				case 113: CPrintToChatAll("{navy}%s %N Connected", strType, iClient);
				case 114: CPrintToChatAll("{normal}%s %N Connected", strType, iClient); // same as Normal item quality in TF2
				case 115: CPrintToChatAll("{oldlace}%s %N Connected", strType, iClient);
				case 116: CPrintToChatAll("{olive}%s %N Connected", strType, iClient);
				case 117: CPrintToChatAll("{olivedrab}%s %N Connected", strType, iClient);
				case 118: CPrintToChatAll("{orange}%s %N Connected", strType, iClient);
				case 119: CPrintToChatAll("{orangered}%s %N Connected", strType, iClient);
				case 120: CPrintToChatAll("{orchid}%s %N Connected", strType, iClient);
				case 121: CPrintToChatAll("{palegoldenrod}%s %N Connected", strType, iClient);
				case 122: CPrintToChatAll("{palegreen}%s %N Connected", strType, iClient);
				case 123: CPrintToChatAll("{paleturquoise}%s %N Connected", strType, iClient);
				case 124: CPrintToChatAll("{palevioletred}%s %N Connected", strType, iClient);
				case 125: CPrintToChatAll("{papayawhip}%s %N Connected", strType, iClient);
				case 126: CPrintToChatAll("{peachpuff}%s %N Connected", strType, iClient);
				case 127: CPrintToChatAll("{peru}%s %N Connected", strType, iClient);
				case 128: CPrintToChatAll("{pink}%s %N Connected", strType, iClient);
				case 129: CPrintToChatAll("{plum}%s %N Connected", strType, iClient);
				case 130: CPrintToChatAll("{powderblue}%s %N Connected", strType, iClient);
				case 131: CPrintToChatAll("{purple}%s %N Connected", strType, iClient);
				case 132: CPrintToChatAll("{red}%s %N Connected", strType, iClient); // same as RED/Terrorist team color
				case 133: CPrintToChatAll("{rosybrown}%s %N Connected", strType, iClient);
				case 134: CPrintToChatAll("{royalblue}%s %N Connected", strType, iClient);
				case 135: CPrintToChatAll("{saddlebrown}%s %N Connected", strType, iClient);
				case 136: CPrintToChatAll("{salmon}%s %N Connected", strType, iClient);
				case 137: CPrintToChatAll("{sandybrown}%s %N Connected", strType, iClient);
				case 138: CPrintToChatAll("{seagreen}%s %N Connected", strType, iClient);
				case 139: CPrintToChatAll("{seashell}%s %N Connected", strType, iClient);
				case 140: CPrintToChatAll("{selfmade}%s %N Connected", strType, iClient); // same as Self-Made item quality in TF2
				case 141: CPrintToChatAll("{sienna}%s %N Connected", strType, iClient);
				case 142: CPrintToChatAll("{silver}%s %N Connected", strType, iClient);
				case 143: CPrintToChatAll("{skyblue}%s %N Connected", strType, iClient);
				case 144: CPrintToChatAll("{slateblue}%s %N Connected", strType, iClient);
				case 145: CPrintToChatAll("{slategray}%s %N Connected", strType, iClient);
				case 146: CPrintToChatAll("{slategrey}%s %N Connected", strType, iClient);
				case 147: CPrintToChatAll("{snow}%s %N Connected", strType, iClient);
				case 148: CPrintToChatAll("{springgreen}%s %N Connected", strType, iClient);
				case 149: CPrintToChatAll("{steelblue}%s %N Connected", strType, iClient);
				case 150: CPrintToChatAll("{strange}%s %N Connected", strType, iClient); // same as Strange item quality in TF2
				case 151: CPrintToChatAll("{tan}%s %N Connected", strType, iClient);
				case 152: CPrintToChatAll("{teal}%s %N Connected", strType, iClient);
				case 153: CPrintToChatAll("{thistle}%s %N Connected", strType, iClient);
				case 154: CPrintToChatAll("{tomato}%s %N Connected", strType, iClient);
				case 155: CPrintToChatAll("{turquoise}%s %N Connected", strType, iClient);
				case 156: CPrintToChatAll("{unique}%s %N Connected", strType, iClient); // same as Unique item quality in TF2
				case 157: CPrintToChatAll("{unusual}%s %N Connected", strType, iClient); // same as Unusual item quality in TF2
				case 158: CPrintToChatAll("{valve}%s %N Connected", strType, iClient); // same as Valve item quality in TF2
				case 159: CPrintToChatAll("{vintage}%s %N Connected", strType, iClient); // same as Vintage item quality in TF2
				case 160: CPrintToChatAll("{violet}%s %N Connected", strType, iClient);
				case 161: CPrintToChatAll("{wheat}%s %N Connected", strType, iClient);
				case 162: CPrintToChatAll("{white}%s %N Connected", strType, iClient);
				case 163: CPrintToChatAll("{whitesmoke}%s %N Connected", strType, iClient);
				case 164: CPrintToChatAll("{yellow}%s %N Connected", strType, iClient);
				case 165: CPrintToChatAll("{yellowgreen}%s %N Connected", strType, iClient);
			}
		}
		if(g_iEnabled & dCenter)
			PrintCenterTextAll("%s %N Connected", strType, iClient);
		if(g_iEnabled & dHud && (g_bGameTF2 || g_bGameHL2MP))
		{
			SetHudTextParams(-1.0, 0.3, 7.5, 255, 255, 255, 255);
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
				ShowHudText(i, -1, "%s %N Connected", strType, iClient);
		}
		if(g_iEnabled & dHint)
			PrintHintTextToAll("%s %N Connected", strType, iClient);
		if(g_iEnabled & dServer)
			PrintToServer("%s %N Connected", strType, iClient);
	}
}

// ====[ STOCKS ]==============================================================
stock IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}
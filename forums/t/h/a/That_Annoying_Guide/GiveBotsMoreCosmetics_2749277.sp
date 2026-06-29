#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.13"

bool g_bTouched[MAXPLAYERS+1] = false;
bool g_bMVM = false;
bool g_bLateLoad = false;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
Handle g_hWearableEquip;

public Plugin myinfo = 
{
	name = "Give Bots More Cosmetics",
	author = "PC Gamer, with code by luki1412 and manicogaming",
	description = "Gives TF2 bots more cosmetics",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	
	if (!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) 
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	ConVar versioncvar = CreateConVar("sm_gbmc_version", PLUGIN_VERSION, "Give Bots More Cosmetics version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbmc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbmc_delay", "0.1", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);

	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(versioncvar, PLUGIN_VERSION);

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
		SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
		SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_bMVM = false;
	}
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (!g_bMVM && !g_bTouched[client] && IsPlayerHere(client))
	{
		RemoveAllWearables(client);
		g_bTouched[client] = true;
		CreateTimer(GetConVarFloat(g_hCVTimer), Timer_GiveHat, userd);
	}
}

public Action Timer_GiveHat(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}
	
	if (IsPlayerHere(client))
	{
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			int rnd3 = GetRandomInt(1,519);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 52, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 111, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 106, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 107, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 150, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 174, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 249, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 219, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 324, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 347, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 346, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 453, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 454, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 468, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 451, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 490, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 491, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 539, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 540, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 617, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 633, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 630, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 547, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 548, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 546, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 652, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 653, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 707, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 722, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 760, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 765, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 781, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 780, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 788, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 846, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 827, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 924, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 5617, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 983, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 859, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 857, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 858, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1026, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 1032, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30027, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30030, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30019, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1040, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30059, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30060, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30076, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30083, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30077, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30134, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30078, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30084, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30185, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30231, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30247, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30248, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30211, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30207, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30253, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30208, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 1075, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30320, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30325, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30332, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30326, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30376, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30427, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30394, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30426, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30428, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30396, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30395, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30471, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30470, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30472, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30479, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30495, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30496, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30492, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30494, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30491, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30493, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30540, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30552, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30574, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30575, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30573, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30561, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30564, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30636, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30661, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30718, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30719, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30686, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30685, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30736, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30737, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30735, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30751, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30754, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30767, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30770, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30771, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30769, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30809, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30824, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30820, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30867, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30869, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30849, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30875, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30890, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30888, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30889, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30993, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30990, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30991, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31001, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31000, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30999, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31021, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31022, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31023, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31042, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31043, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31056, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31081, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31082, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31083, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31117, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 31118, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 31116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 31119, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 31138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 31195, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 31197, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 31196, 10, 6, 1);			
				}
			case 517:
				{
					//do nothing/keep stock
				}
			case 518:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,519);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 52, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 111, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 106, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 107, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 150, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 174, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 249, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 219, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 324, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 347, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 346, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 453, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 454, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 468, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 451, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 490, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 491, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 539, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 540, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 617, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 633, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 630, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 547, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 548, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 546, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 652, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 653, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 707, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 722, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 760, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 765, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 781, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 780, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 788, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 846, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 827, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 924, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 5617, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 983, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 859, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 857, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 858, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1026, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 1032, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30027, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30030, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30019, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1040, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30059, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30060, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30076, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30083, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30077, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30134, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30078, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30084, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30185, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30231, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30247, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30248, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30211, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30207, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30253, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30208, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 1075, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30320, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30325, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30332, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30326, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30376, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30427, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30394, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30426, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30428, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30396, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30395, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30471, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30470, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30472, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30479, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30495, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30496, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30492, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30494, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30491, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30493, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30540, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30552, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30574, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30575, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30573, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30561, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30564, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30636, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30661, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30718, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30719, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30686, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30685, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30736, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30737, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30735, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30751, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30754, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30767, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30770, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30771, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30769, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30809, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30824, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30820, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30867, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30869, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30849, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30875, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30890, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30888, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30889, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30993, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30990, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30991, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31001, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31000, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30999, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31021, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31022, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31023, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31042, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31043, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31056, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31081, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31082, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31083, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31117, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 31118, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 31116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 31119, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 31138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 31195, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 31197, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 31196, 10, 6, 1);			
				}
			case 517:
				{
					//do nothing/keep stock
				}
			case 518:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,519);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 52, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 111, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 106, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 107, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 150, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 174, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 249, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 219, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 324, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 347, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 346, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 453, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 454, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 468, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 451, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 490, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 491, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 539, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 540, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 617, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 633, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 630, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 547, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 548, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 546, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 652, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 653, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 707, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 722, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 760, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 765, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 781, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 780, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 788, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 846, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 827, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 924, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 5617, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 983, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 859, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 857, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 858, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1026, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 1032, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30027, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30030, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30019, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1040, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30059, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30060, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30076, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30083, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30077, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30134, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30078, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30084, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30185, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30231, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30247, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30248, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30211, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30207, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30253, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30208, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 1075, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30320, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30325, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30332, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30326, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30376, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30427, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30394, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30426, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30428, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30396, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30395, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30471, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30470, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30472, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30479, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30495, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30496, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30492, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30494, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30491, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30493, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30540, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30552, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30574, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30575, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30573, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30561, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30564, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30636, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30661, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30718, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30719, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30686, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30685, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30736, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30737, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30735, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30751, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30754, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30767, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30770, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30771, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30769, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30809, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30824, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30820, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30867, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30869, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30849, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30875, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30890, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30888, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30889, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30993, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30990, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30991, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31001, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31000, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30999, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31021, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31022, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31023, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31042, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31043, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31056, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31081, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31082, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31083, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31117, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 31118, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 31116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 31119, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 31138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 31195, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 31197, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 31196, 10, 6, 1);			
				}
			case 517:
				{
					//do nothing/keep stock
				}
			case 518:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			int rnd3 = GetRandomInt(1,512);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 54, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 121, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 98, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 99, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 152, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 183, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 240, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 250, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 251, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 227, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 340, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 339, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 360, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 391, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 434, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 395, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 445, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 446, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 417, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 440, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 439, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 516, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 555, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 575, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 557, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 556, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 650, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 701, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 719, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 721, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 764, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 731, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 732, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 852, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 844, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 829, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 5618, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 926, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 945, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 980, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 1021, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30026, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30033, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30017, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30014, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30071, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30131, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30116, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30117, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30115, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30142, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30129, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30130, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30120, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30126, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30114, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30118, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30251, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30227, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30239, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30221, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30264, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30228, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30265, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30294, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30276, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30281, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30266, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30268, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 1073, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 1074, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30331, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30335, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30314, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30338, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30339, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 1090, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 1091, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 1093, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30388, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30392, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30390, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30477, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30524, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30520, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30521, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30522, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30558, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30553, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30554, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30548, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30601, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30578, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30708, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30727, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30744, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30780, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30853, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30896, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30899, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30885, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30898, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30897, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30969, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30985, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30984, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30983, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31002, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31003, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31025, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31024, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31035, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31045, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31044, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31069, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31070, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31071, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31095, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31112, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31113, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31111, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31146, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31147, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31137, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31199, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31198, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31200, 10, 6, 1);			
				}
			case 510:
				{
					//do nothing/keep stock			
				}
			case 511:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,512);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 54, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 121, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 98, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 99, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 152, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 183, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 240, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 250, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 251, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 227, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 340, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 339, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 360, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 391, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 434, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 395, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 445, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 446, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 417, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 440, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 439, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 516, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 555, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 575, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 557, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 556, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 650, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 701, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 719, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 721, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 764, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 731, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 732, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 852, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 844, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 829, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 5618, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 926, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 945, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 980, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 1021, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30026, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30033, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30017, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30014, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30071, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30131, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30116, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30117, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30115, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30142, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30129, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30130, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30120, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30126, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30114, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30118, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30251, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30227, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30239, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30221, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30264, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30228, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30265, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30294, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30276, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30281, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30266, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30268, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 1073, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 1074, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30331, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30335, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30314, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30338, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30339, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 1090, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 1091, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 1093, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30388, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30392, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30390, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30477, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30524, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30520, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30521, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30522, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30558, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30553, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30554, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30548, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30601, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30578, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30708, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30727, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30744, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30780, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30853, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30896, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30899, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30885, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30898, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30897, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30969, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30985, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30984, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30983, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31002, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31003, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31025, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31024, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31035, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31045, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31044, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31069, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31070, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31071, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31095, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31112, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31113, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31111, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31146, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31147, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31137, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31199, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31198, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31200, 10, 6, 1);			
				}
			case 510:
				{
					//do nothing/keep stock			
				}
			case 511:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,512);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 54, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 121, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 98, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 99, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 152, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 183, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 240, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 250, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 251, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 227, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 340, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 339, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 360, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 391, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 434, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 395, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 445, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 446, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 417, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 440, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 439, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 516, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 555, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 575, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 557, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 556, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 650, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 701, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 719, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 721, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 764, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 731, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 732, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 852, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 844, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 829, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 5618, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 926, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 945, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 980, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 1021, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30026, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30033, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30017, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30014, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30071, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30131, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30116, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30117, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30115, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30142, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30129, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30130, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30120, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30126, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30114, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30118, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30251, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30227, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30239, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30221, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30264, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30228, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30265, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30294, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30276, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30281, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30266, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30268, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 1073, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 1074, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30331, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30335, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30314, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30338, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30339, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 1090, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 1091, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 1093, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30388, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30392, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30390, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30477, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30524, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30520, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30521, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30522, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30558, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30553, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30554, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30548, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30601, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30578, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30708, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30727, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30744, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30780, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30853, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30896, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30899, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30885, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30898, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30897, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30969, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30985, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30984, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30983, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31002, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31003, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31025, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31024, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31035, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31045, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31044, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31069, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31070, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31071, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31095, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31112, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31113, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31111, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31146, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 31147, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 31137, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31199, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31198, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31200, 10, 6, 1);			
				}
			case 510:
				{
					//do nothing/keep stock			
				}
			case 511:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			int rnd3 = GetRandomInt(1,561);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 51, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 105, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 102, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 151, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 182, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 175, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 213, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 253, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 248, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 247, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 335, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 336, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 318, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 321, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 316, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 387, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 435, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 394, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 377, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 481, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 615, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 632, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 627, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 612, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 571, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 549, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 550, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 570, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 551, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 597, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 644, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 651, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 596, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 753, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 761, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 746, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 745, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 820, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 787, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 842, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 854, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 856, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 938, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 923, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 5624, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 937, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 950, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 951, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1020, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 1031, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30057, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30025, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30036, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30038, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30053, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30028, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30022, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30040, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30039, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30032, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30020, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 1038, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30075, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30063, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30062, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30090, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30091, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30093, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30139, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30092, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30163, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30162, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30176, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30169, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30303, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30191, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30245, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30203, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30288, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30225, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30285, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30296, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30204, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30257, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30216, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30286, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30222, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30277, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30267, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30192, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30220, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30269, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30196, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30259, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30235, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30290, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30298, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30218, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30205, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30194, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30213, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30273, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 1072, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30304, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30321, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30327, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30308, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30355, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30418, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30416, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30417, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30398, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30400, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30391, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30399, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30475, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30526, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30525, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30528, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30527, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30529, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30530, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 1124, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30544, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30538, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30582, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30584, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 30580, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 30581, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30583, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 30662, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 30663, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 30652, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 30664, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 30717, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 30716, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 30676, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 30684, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 30724, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 30721, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 30799, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 30800, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 30795, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 30819, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 30835, 10, 6, 1);			
				}
			case 517:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 518:
				{
					CreateHat(client, 30826, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 30859, 10, 6, 1);			
				}
			case 520:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 521:
				{
					CreateHat(client, 30902, 10, 6, 1);			
				}
			case 522:
				{
					CreateHat(client, 30901, 10, 6, 1);			
				}
			case 523:
				{
					CreateHat(client, 30903, 10, 6, 1);			
				}
			case 524:
				{
					CreateHat(client, 30900, 10, 6, 1);			
				}
			case 525:
				{
					CreateHat(client, 30905, 10, 6, 1);			
				}
			case 526:
				{
					CreateHat(client, 30904, 10, 6, 1);			
				}
			case 527:
				{
					CreateHat(client, 30936, 10, 6, 1);			
				}
			case 528:
				{
					CreateHat(client, 30937, 10, 6, 1);			
				}
			case 529:
				{
					CreateHat(client, 30987, 10, 6, 1);			
				}
			case 530:
				{
					CreateHat(client, 30986, 10, 6, 1);			
				}
			case 531:
				{
					CreateHat(client, 31007, 10, 6, 1);			
				}
			case 532:
				{
					CreateHat(client, 31006, 10, 6, 1);			
				}
			case 533:
				{
					CreateHat(client, 31004, 10, 6, 1);			
				}
			case 534:
				{
					CreateHat(client, 31026, 10, 6, 1);			
				}
			case 535:
				{
					CreateHat(client, 31047, 10, 6, 1);			
				}
			case 536:
				{
					CreateHat(client, 31041, 10, 6, 1);			
				}
			case 537:
				{
					CreateHat(client, 31050, 10, 6, 1);			
				}
			case 538:
				{
					CreateHat(client, 31051, 10, 6, 1);			
				}
			case 539:
				{
					CreateHat(client, 31067, 10, 6, 1);			
				}
			case 540:
				{
					CreateHat(client, 31065, 10, 6, 1);			
				}
			case 541:
				{
					CreateHat(client, 31076, 10, 6, 1);			
				}
			case 542:
				{
					CreateHat(client, 31068, 10, 6, 1);			
				}
			case 543:
				{
					CreateHat(client, 31066, 10, 6, 1);			
				}
			case 544:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 545:
				{
					CreateHat(client, 31096, 10, 6, 1);			
				}
			case 546:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 547:
				{
					CreateHat(client, 31108, 10, 6, 1);			
				}
			case 548:
				{
					CreateHat(client, 31107, 10, 6, 1);			
				}
			case 549:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 550:
				{
					CreateHat(client, 31144, 10, 6, 1);			
				}
			case 551:
				{
					CreateHat(client, 31145, 10, 6, 1);			
				}
			case 552:
				{
					CreateHat(client, 31143, 10, 6, 1);			
				}
			case 553:
				{
					CreateHat(client, 31141, 10, 6, 1);			
				}
			case 554:
				{
					CreateHat(client, 31174, 10, 6, 1);			
				}
			case 555:
				{
					CreateHat(client, 31185, 10, 6, 1);			
				}
			case 556:
				{
					CreateHat(client, 31187, 10, 6, 1);			
				}
			case 557:
				{
					CreateHat(client, 31186, 10, 6, 1);			
				}
			case 558:
				{
					CreateHat(client, 31188, 10, 6, 1);			
				}
			case 559:
				{
					//empty spot			
				}
			case 560:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 561:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,561);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 51, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 105, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 102, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 151, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 182, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 175, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 213, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 253, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 248, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 247, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 335, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 336, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 318, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 321, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 316, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 387, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 435, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 394, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 377, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 481, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 615, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 632, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 627, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 612, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 571, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 549, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 550, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 570, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 551, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 597, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 644, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 651, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 596, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 753, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 761, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 746, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 745, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 820, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 787, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 842, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 854, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 856, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 938, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 923, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 5624, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 937, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 950, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 951, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1020, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 1031, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30057, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30025, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30036, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30038, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30053, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30028, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30022, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30040, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30039, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30032, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30020, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 1038, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30075, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30063, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30062, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30090, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30091, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30093, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30139, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30092, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30163, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30162, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30176, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30169, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30303, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30191, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30245, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30203, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30288, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30225, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30285, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30296, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30204, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30257, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30216, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30286, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30222, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30277, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30267, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30192, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30220, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30269, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30196, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30259, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30235, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30290, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30298, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30218, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30205, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30194, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30213, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30273, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 1072, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30304, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30321, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30327, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30308, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30355, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30418, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30416, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30417, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30398, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30400, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30391, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30399, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30475, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30526, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30525, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30528, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30527, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30529, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30530, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 1124, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30544, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30538, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30582, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30584, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 30580, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 30581, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30583, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 30662, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 30663, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 30652, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 30664, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 30717, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 30716, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 30676, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 30684, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 30724, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 30721, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 30799, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 30800, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 30795, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 30819, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 30835, 10, 6, 1);			
				}
			case 517:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 518:
				{
					CreateHat(client, 30826, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 30859, 10, 6, 1);			
				}
			case 520:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 521:
				{
					CreateHat(client, 30902, 10, 6, 1);			
				}
			case 522:
				{
					CreateHat(client, 30901, 10, 6, 1);			
				}
			case 523:
				{
					CreateHat(client, 30903, 10, 6, 1);			
				}
			case 524:
				{
					CreateHat(client, 30900, 10, 6, 1);			
				}
			case 525:
				{
					CreateHat(client, 30905, 10, 6, 1);			
				}
			case 526:
				{
					CreateHat(client, 30904, 10, 6, 1);			
				}
			case 527:
				{
					CreateHat(client, 30936, 10, 6, 1);			
				}
			case 528:
				{
					CreateHat(client, 30937, 10, 6, 1);			
				}
			case 529:
				{
					CreateHat(client, 30987, 10, 6, 1);			
				}
			case 530:
				{
					CreateHat(client, 30986, 10, 6, 1);			
				}
			case 531:
				{
					CreateHat(client, 31007, 10, 6, 1);			
				}
			case 532:
				{
					CreateHat(client, 31006, 10, 6, 1);			
				}
			case 533:
				{
					CreateHat(client, 31004, 10, 6, 1);			
				}
			case 534:
				{
					CreateHat(client, 31026, 10, 6, 1);			
				}
			case 535:
				{
					CreateHat(client, 31047, 10, 6, 1);			
				}
			case 536:
				{
					CreateHat(client, 31041, 10, 6, 1);			
				}
			case 537:
				{
					CreateHat(client, 31050, 10, 6, 1);			
				}
			case 538:
				{
					CreateHat(client, 31051, 10, 6, 1);			
				}
			case 539:
				{
					CreateHat(client, 31067, 10, 6, 1);			
				}
			case 540:
				{
					CreateHat(client, 31065, 10, 6, 1);			
				}
			case 541:
				{
					CreateHat(client, 31076, 10, 6, 1);			
				}
			case 542:
				{
					CreateHat(client, 31068, 10, 6, 1);			
				}
			case 543:
				{
					CreateHat(client, 31066, 10, 6, 1);			
				}
			case 544:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 545:
				{
					CreateHat(client, 31096, 10, 6, 1);			
				}
			case 546:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 547:
				{
					CreateHat(client, 31108, 10, 6, 1);			
				}
			case 548:
				{
					CreateHat(client, 31107, 10, 6, 1);			
				}
			case 549:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 550:
				{
					CreateHat(client, 31144, 10, 6, 1);			
				}
			case 551:
				{
					CreateHat(client, 31145, 10, 6, 1);			
				}
			case 552:
				{
					CreateHat(client, 31143, 10, 6, 1);			
				}
			case 553:
				{
					CreateHat(client, 31141, 10, 6, 1);			
				}
			case 554:
				{
					CreateHat(client, 31174, 10, 6, 1);			
				}
			case 555:
				{
					CreateHat(client, 31185, 10, 6, 1);			
				}
			case 556:
				{
					CreateHat(client, 31187, 10, 6, 1);			
				}
			case 557:
				{
					CreateHat(client, 31186, 10, 6, 1);			
				}
			case 558:
				{
					CreateHat(client, 31188, 10, 6, 1);			
				}
			case 559:
				{
					//empty spot			
				}
			case 560:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 561:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,561);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 51, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 105, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 102, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 151, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 182, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 175, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 213, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 253, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 248, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 247, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 335, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 336, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 318, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 321, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 316, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 387, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 435, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 394, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 377, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 481, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 615, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 632, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 627, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 612, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 571, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 549, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 550, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 570, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 551, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 597, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 644, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 651, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 596, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 753, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 761, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 746, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 745, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 820, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 787, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 842, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 854, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 856, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 938, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 923, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 5624, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 937, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 950, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 951, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1020, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 1031, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30057, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30025, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30036, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30038, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30053, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30028, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30022, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30040, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30039, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30032, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30020, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 1038, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30075, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30063, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30062, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30090, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30091, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30093, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30139, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30092, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30163, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30162, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30176, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30169, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30303, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30191, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30245, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30203, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30288, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30225, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30285, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30296, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30204, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30257, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30216, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30286, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30222, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30277, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30267, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30192, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30220, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30269, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30196, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30259, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30235, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30290, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30298, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30218, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30205, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30194, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30213, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30273, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30236, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 1072, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30304, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30321, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30327, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30308, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30355, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30418, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30416, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30417, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30398, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30400, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30391, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30399, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30475, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30526, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30525, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30528, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30527, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30529, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30530, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 1124, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 30544, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 30538, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 30582, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 30584, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 30580, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 30581, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 30583, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 30662, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 30663, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 30652, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 30664, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 30717, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 30716, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 30676, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 30684, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 30724, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 30721, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 30799, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 30800, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 30795, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 30819, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 507:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 508:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 510:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 511:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 512:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 513:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 514:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 515:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 516:
				{
					CreateHat(client, 30835, 10, 6, 1);			
				}
			case 517:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 518:
				{
					CreateHat(client, 30826, 10, 6, 1);			
				}
			case 519:
				{
					CreateHat(client, 30859, 10, 6, 1);			
				}
			case 520:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 521:
				{
					CreateHat(client, 30902, 10, 6, 1);			
				}
			case 522:
				{
					CreateHat(client, 30901, 10, 6, 1);			
				}
			case 523:
				{
					CreateHat(client, 30903, 10, 6, 1);			
				}
			case 524:
				{
					CreateHat(client, 30900, 10, 6, 1);			
				}
			case 525:
				{
					CreateHat(client, 30905, 10, 6, 1);			
				}
			case 526:
				{
					CreateHat(client, 30904, 10, 6, 1);			
				}
			case 527:
				{
					CreateHat(client, 30936, 10, 6, 1);			
				}
			case 528:
				{
					CreateHat(client, 30937, 10, 6, 1);			
				}
			case 529:
				{
					CreateHat(client, 30987, 10, 6, 1);			
				}
			case 530:
				{
					CreateHat(client, 30986, 10, 6, 1);			
				}
			case 531:
				{
					CreateHat(client, 31007, 10, 6, 1);			
				}
			case 532:
				{
					CreateHat(client, 31006, 10, 6, 1);			
				}
			case 533:
				{
					CreateHat(client, 31004, 10, 6, 1);			
				}
			case 534:
				{
					CreateHat(client, 31026, 10, 6, 1);			
				}
			case 535:
				{
					CreateHat(client, 31047, 10, 6, 1);			
				}
			case 536:
				{
					CreateHat(client, 31041, 10, 6, 1);			
				}
			case 537:
				{
					CreateHat(client, 31050, 10, 6, 1);			
				}
			case 538:
				{
					CreateHat(client, 31051, 10, 6, 1);			
				}
			case 539:
				{
					CreateHat(client, 31067, 10, 6, 1);			
				}
			case 540:
				{
					CreateHat(client, 31065, 10, 6, 1);			
				}
			case 541:
				{
					CreateHat(client, 31076, 10, 6, 1);			
				}
			case 542:
				{
					CreateHat(client, 31068, 10, 6, 1);			
				}
			case 543:
				{
					CreateHat(client, 31066, 10, 6, 1);			
				}
			case 544:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 545:
				{
					CreateHat(client, 31096, 10, 6, 1);			
				}
			case 546:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 547:
				{
					CreateHat(client, 31108, 10, 6, 1);			
				}
			case 548:
				{
					CreateHat(client, 31107, 10, 6, 1);			
				}
			case 549:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 550:
				{
					CreateHat(client, 31144, 10, 6, 1);			
				}
			case 551:
				{
					CreateHat(client, 31145, 10, 6, 1);			
				}
			case 552:
				{
					CreateHat(client, 31143, 10, 6, 1);			
				}
			case 553:
				{
					CreateHat(client, 31141, 10, 6, 1);			
				}
			case 554:
				{
					CreateHat(client, 31174, 10, 6, 1);			
				}
			case 555:
				{
					CreateHat(client, 31185, 10, 6, 1);			
				}
			case 556:
				{
					CreateHat(client, 31187, 10, 6, 1);			
				}
			case 557:
				{
					CreateHat(client, 31186, 10, 6, 1);			
				}
			case 558:
				{
					CreateHat(client, 31188, 10, 6, 1);			
				}
			case 559:
				{
					//empty spot			
				}
			case 560:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 561:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			int rnd3 = GetRandomInt(1,498);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 47, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 100, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 120, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 146, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 179, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 259, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 216, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 255, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 295, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 342, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 306, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 359, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 390, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 465, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 403, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 480, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 514, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 610, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 607, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 543, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 545, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 544, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 703, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 708, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 709, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 771, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 776, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 786, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 845, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 830, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 874, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 935, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 5620, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1019, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30034, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30011, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30029, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30024, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30016, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30010, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30021, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30055, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30037, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30073, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30064, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30061, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30105, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30124, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30107, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30082, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30112, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30106, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30110, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30179, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30180, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30193, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30240, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30243, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30249, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30282, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30292, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30226, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30219, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30241, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30333, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30334, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30348, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30363, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30366, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30340, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30429, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30421, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30393, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30430, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30431, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30480, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30518, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30517, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30516, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30519, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30547, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30555, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30541, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30604, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30587, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30586, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30627, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30628, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30723, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30742, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30779, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30788, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30793, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30807, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30823, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30830, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30836, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30863, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30945, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30954, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30973, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30979, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31017, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31039, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31038, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31037, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31040, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31100, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31115, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31182, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 496:
				{
					//nothing			
				}
			case 497:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,498);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 47, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 100, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 120, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 146, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 179, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 259, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 216, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 255, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 295, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 342, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 306, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 359, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 390, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 465, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 403, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 480, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 514, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 610, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 607, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 543, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 545, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 544, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 703, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 708, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 709, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 771, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 776, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 786, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 845, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 830, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 874, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 935, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 5620, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1019, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30034, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30011, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30029, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30024, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30016, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30010, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30021, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30055, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30037, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30073, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30064, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30061, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30105, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30124, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30107, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30082, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30112, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30106, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30110, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30179, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30180, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30193, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30240, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30243, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30249, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30282, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30292, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30226, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30219, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30241, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30333, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30334, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30348, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30363, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30366, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30340, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30429, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30421, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30393, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30430, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30431, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30480, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30518, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30517, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30516, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30519, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30547, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30555, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30541, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30604, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30587, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30586, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30627, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30628, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30723, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30742, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30779, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30788, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30793, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30807, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30823, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30830, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30836, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30863, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30945, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30954, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30973, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30979, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31017, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31039, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31038, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31037, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31040, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31100, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31115, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31182, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 496:
				{
					//nothing			
				}
			case 497:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,498);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 47, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 100, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 120, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 146, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 179, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 259, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 216, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 255, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 295, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 342, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 306, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 359, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 390, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 465, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 403, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 480, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 514, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 610, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 607, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 543, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 545, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 544, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 641, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 703, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 708, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 709, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 768, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 771, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 776, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 786, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 845, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 830, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 874, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 875, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 922, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 935, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 5620, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 976, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1016, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1019, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30034, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30011, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30029, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30024, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30016, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30010, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30021, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30055, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30037, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30073, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30064, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30061, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30105, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30124, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30107, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30082, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30112, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30106, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30110, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30179, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30180, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30200, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30242, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30193, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30240, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30243, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30249, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30282, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30292, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30226, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30219, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30241, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30333, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30334, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30305, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30348, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30363, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30366, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30358, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30340, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30429, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30421, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30393, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30430, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30431, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30480, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30518, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30517, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30516, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30519, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30547, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30555, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30541, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30604, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30587, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30586, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30627, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30628, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30723, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30742, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30779, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30788, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30793, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30807, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30823, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30830, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30836, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30818, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30822, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30863, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30886, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30945, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30954, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30973, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30979, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31017, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31039, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31038, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31057, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31037, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31040, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31100, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31115, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31182, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 496:
				{
					//nothing			
				}
			case 497:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			int rnd3 = GetRandomInt(1,509);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 49, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 96, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 97, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 145, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 185, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 254, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 246, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 290, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 292, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 309, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 330, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 313, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 358, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 380, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 427, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 485, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 478, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 479, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 515, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 517, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 524, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 535, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 613, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 601, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 603, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 561, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 562, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 585, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 635, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 643, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 757, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 777, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 840, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 5519, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 821, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 866, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 930, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 932, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 931, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 946, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 990, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 952, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 989, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 985, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 991, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1018, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 1028, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30054, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30013, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30012, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30049, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30074, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30122, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30108, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30138, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30141, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30080, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30094, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30079, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30081, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30238, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30275, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30217, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30199, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30280, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30319, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30315, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30344, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30372, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30369, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30343, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30342, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30345, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30354, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30374, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30346, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30368, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30364, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 1097, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 1087, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 1088, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30401, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30482, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30531, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30532, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30534, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30533, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30563, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30545, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30557, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30556, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30589, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30588, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30633, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30644, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30645, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30653, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30745, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30803, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30815, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30812, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30866, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 1188, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 1187, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 1189, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30914, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30912, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30911, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30910, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30913, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30959, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30960, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30964, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30981, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30980, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31008, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31029, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31030, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31053, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31052, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31080, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31079, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31123, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31142, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31180, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31179, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31178, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31190, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31191, 10, 6, 1);			
				}
			case 507:
				{
					//do nothing			
				}
			case 508:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,509);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 49, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 96, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 97, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 145, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 185, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 254, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 246, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 290, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 292, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 309, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 330, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 313, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 358, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 380, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 427, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 485, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 478, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 479, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 515, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 517, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 524, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 535, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 613, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 601, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 603, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 561, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 562, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 585, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 635, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 643, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 757, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 777, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 840, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 5519, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 821, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 866, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 930, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 932, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 931, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 946, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 990, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 952, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 989, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 985, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 991, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1018, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 1028, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30054, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30013, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30012, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30049, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30074, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30122, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30108, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30138, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30141, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30080, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30094, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30079, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30081, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30238, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30275, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30217, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30199, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30280, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30319, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30315, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30344, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30372, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30369, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30343, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30342, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30345, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30354, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30374, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30346, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30368, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30364, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 1097, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 1087, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 1088, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30401, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30482, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30531, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30532, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30534, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30533, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30563, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30545, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30557, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30556, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30589, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30588, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30633, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30644, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30645, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30653, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30745, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30803, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30815, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30812, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30866, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 1188, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 1187, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 1189, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30914, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30912, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30911, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30910, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30913, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30959, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30960, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30964, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30981, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30980, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31008, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31029, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31030, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31053, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31052, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31080, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31079, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31123, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31142, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31180, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31179, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31178, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31190, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31191, 10, 6, 1);			
				}
			case 507:
				{
					//do nothing			
				}
			case 508:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,509);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 49, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 96, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 97, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 145, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 185, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 254, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 246, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 290, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 292, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 309, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 330, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 313, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 358, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 380, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 427, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 392, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 485, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 478, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 479, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 515, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 517, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 524, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 535, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 613, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 601, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 603, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 561, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 562, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 585, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 635, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 643, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 757, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 777, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 840, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 5519, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 821, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 866, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 876, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 930, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 932, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 931, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 946, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 990, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 952, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 989, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 985, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 991, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 1018, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 1028, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30054, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30013, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30012, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30049, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30074, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30122, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30108, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30138, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30141, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30080, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30094, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30079, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30081, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30178, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30238, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30275, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30217, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30199, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30280, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30319, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30315, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30344, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30372, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30369, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30343, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30342, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30345, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30354, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30374, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30346, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30368, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30364, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 1097, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 1087, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 1088, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30401, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30482, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30531, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30532, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30534, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30533, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30563, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30545, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30557, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30556, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30589, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30588, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30633, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30644, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30645, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30653, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30745, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30747, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30803, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30815, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30812, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30811, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30866, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 1188, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 1187, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 1189, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30914, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30912, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 30911, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 30910, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 30913, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 30959, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 30960, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 30964, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 30981, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 30980, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31008, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31029, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31030, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31053, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31052, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31080, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31079, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31123, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31142, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31180, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31179, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 31178, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 503:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 504:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31190, 10, 6, 1);			
				}
			case 506:
				{
					CreateHat(client, 31191, 10, 6, 1);			
				}
			case 507:
				{
					//do nothing			
				}
			case 508:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 509:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			int rnd3 = GetRandomInt(1,505);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 48, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 95, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 118, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 94, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 148, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 178, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 322, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 338, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 382, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 389, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 384, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 386, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 436, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 399, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 379, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 484, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 519, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 520, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 533, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 606, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 528, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 567, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 568, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 569, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 591, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 590, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 670, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 755, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 784, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 848, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 823, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 918, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 5621, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 988, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 1009, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 1010, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1008, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1017, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30051, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30031, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30023, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30044, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30035, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30070, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30087, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30113, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30099, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30086, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30172, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30223, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30330, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30322, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30377, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30341, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30347, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30336, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 1089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30420, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30408, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30412, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30403, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30407, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30409, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30406, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30402, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30509, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30523, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30508, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30510, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30511, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30539, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30543, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30593, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30592, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30591, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30590, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30605, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30634, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30635, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30654, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30655, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30680, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30681, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30707, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30698, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30675, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30682, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30749, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30785, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30806, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30804, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30794, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30805, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30821, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30381, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30871, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30872, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30846, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30908, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30909, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30992, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30994, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31012, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31011, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30995, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31013, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 31032, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31031, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31049, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31046, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31075, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31074, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31097, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31098, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31114, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31151, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31150, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31140, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31148, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31175, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31189, 10, 6, 1);			
				}
			case 503:
				{
					//do nothing/keep stock			
				}
			case 504:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,505);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 48, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 95, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 118, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 94, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 148, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 178, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 322, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 338, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 382, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 389, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 384, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 386, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 436, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 399, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 379, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 484, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 519, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 520, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 533, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 606, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 528, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 567, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 568, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 569, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 591, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 590, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 670, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 755, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 784, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 848, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 823, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 918, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 5621, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 988, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 1009, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 1010, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1008, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1017, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30051, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30031, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30023, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30044, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30035, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30070, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30087, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30113, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30099, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30086, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30172, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30223, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30330, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30322, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30377, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30341, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30347, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30336, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 1089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30420, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30408, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30412, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30403, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30407, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30409, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30406, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30402, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30509, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30523, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30508, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30510, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30511, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30539, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30543, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30593, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30592, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30591, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30590, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30605, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30634, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30635, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30654, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30655, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30680, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30681, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30707, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30698, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30675, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30682, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30749, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30785, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30806, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30804, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30794, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30805, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30821, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30381, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30871, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30872, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30846, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30908, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30909, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30992, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30994, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31012, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31011, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30995, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31013, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 31032, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31031, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31049, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31046, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31075, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31074, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31097, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31098, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31114, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31151, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31150, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31140, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31148, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31175, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31189, 10, 6, 1);			
				}
			case 503:
				{
					//do nothing/keep stock			
				}
			case 504:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,505);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 48, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 95, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 118, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 94, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 148, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 178, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 322, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 338, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 382, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 389, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 384, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 386, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 436, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 399, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 379, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 484, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 519, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 520, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 533, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 606, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 605, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 528, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 567, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 568, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 569, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 591, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 590, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 670, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 755, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 784, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 848, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 823, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 918, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 5621, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 948, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 988, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 1009, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 1010, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 1008, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1017, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30051, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30031, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30023, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30044, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30035, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30070, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30087, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30113, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30099, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30086, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30167, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30165, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30172, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30168, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30164, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30223, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30330, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30322, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30377, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30367, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30341, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30347, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30336, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 1089, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30420, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30408, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30412, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30403, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30407, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30409, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30406, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30402, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30509, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30523, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30508, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30510, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30511, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30539, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30543, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30593, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30592, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30591, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30590, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30605, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30634, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30635, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30654, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30655, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30680, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30681, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30707, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30698, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30675, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30682, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30749, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30785, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30806, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30804, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30794, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30805, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30821, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30381, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30871, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 30872, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 30846, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 30908, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 30909, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 30930, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 30992, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 30994, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31012, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31011, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 30995, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31013, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 31032, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 31031, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 31049, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 31046, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 31075, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 31074, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 31064, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 31097, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 31098, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 31114, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 31106, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 31133, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 31151, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 31150, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 31140, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 31148, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 31175, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 483:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 484:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 486:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 487:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 488:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 489:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 490:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 491:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 492:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 493:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 494:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 495:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 496:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 497:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 498:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 499:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 500:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 501:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 502:
				{
					CreateHat(client, 31189, 10, 6, 1);			
				}
			case 503:
				{
					//do nothing/keep stock			
				}
			case 504:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 505:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			int rnd3 = GetRandomInt(1,485);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 50, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 104, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 101, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 144, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 184, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 177, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 303, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 315, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 323, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 363, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 383, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 381, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 398, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 467, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 620, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 616, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 621, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 552, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 554, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 657, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 769, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 770, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 778, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 828, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 843, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 826, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 867, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 878, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5622, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 978, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 982, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30052, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30041, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30048, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30042, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30046, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30050, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30045, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30043, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1039, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30136, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30137, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30096, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30127, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30095, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30121, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30098, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30109, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30097, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30186, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30171, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30187, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30190, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30224, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30279, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30232, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30229, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30237, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30299, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30197, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30270, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30230, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30293, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30233, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30263, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30312, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30318, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30311, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30323, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30361, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30350, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30349, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30379, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30356, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30378, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30365, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30351, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30419, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30415, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30410, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30483, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30487, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30486, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30488, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30514, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30489, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30490, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30515, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30596, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30595, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30625, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30626, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30755, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30756, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30750, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30786, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30773, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30817, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30792, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30813, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30825, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30862, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30907, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30906, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30939, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30940, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30982, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31034, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31027, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31028, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31078, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31077, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 31099, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 31121, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 31122, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31139, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31176, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 31177, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 483:
				{
					//stock			
				}
			case 484:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,485);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 50, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 104, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 101, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 144, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 184, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 177, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 303, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 315, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 323, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 363, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 383, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 381, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 398, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 467, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 620, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 616, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 621, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 552, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 554, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 657, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 769, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 770, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 778, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 828, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 843, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 826, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 867, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 878, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5622, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 978, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 982, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30052, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30041, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30048, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30042, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30046, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30050, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30045, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30043, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1039, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30136, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30137, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30096, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30127, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30095, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30121, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30098, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30109, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30097, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30186, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30171, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30187, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30190, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30224, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30279, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30232, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30229, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30237, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30299, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30197, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30270, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30230, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30293, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30233, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30263, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30312, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30318, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30311, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30323, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30361, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30350, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30349, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30379, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30356, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30378, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30365, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30351, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30419, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30415, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30410, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30483, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30487, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30486, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30488, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30514, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30489, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30490, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30515, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30596, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30595, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30625, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30626, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30755, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30756, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30750, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30786, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30773, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30817, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30792, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30813, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30825, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30862, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30907, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30906, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30939, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30940, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30982, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31034, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31027, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31028, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31078, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31077, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 31099, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 31121, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 31122, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31139, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31176, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 31177, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 483:
				{
					//stock			
				}
			case 484:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,485);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 50, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 104, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 101, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 144, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 184, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 177, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 303, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 315, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 323, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 363, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 383, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 381, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 398, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 378, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 467, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 620, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 616, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 621, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 563, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 552, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 554, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 657, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 754, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 769, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 770, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 778, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 828, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 853, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 843, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 826, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 867, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 878, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5622, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 978, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 982, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 1012, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30052, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30041, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30048, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30042, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30046, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30050, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30045, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30043, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 1039, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30136, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30137, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30096, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30127, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30095, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30121, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30098, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30109, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30097, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30186, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30171, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30187, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30190, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30224, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30279, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30232, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30229, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30237, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30299, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30197, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30270, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30230, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30293, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30233, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30263, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30312, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30318, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30311, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30323, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30361, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30350, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30349, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30379, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30356, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30378, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30365, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30351, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30419, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30415, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30410, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30483, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30487, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30486, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30488, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30514, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30489, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30490, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30515, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30596, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30595, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30625, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30626, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30755, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30756, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30750, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30786, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30773, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30817, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30792, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30813, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 30825, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 30862, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 30907, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 30906, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 30939, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 30940, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 30982, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31034, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31027, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31028, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31078, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31077, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 31099, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 31121, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 31122, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 31139, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 31176, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 31177, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 478:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 479:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 481:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 482:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 483:
				{
					//stock			
				}
			case 484:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 485:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			int rnd3 = GetRandomInt(1,480);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 53, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 110, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 109, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 117, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 158, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 181, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 229, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 314, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 344, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 393, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 400, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 518, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 534, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 618, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 626, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 600, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 566, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 564, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 565, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 645, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 720, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 759, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 762, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 779, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 819, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 847, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 824, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 877, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 917, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 5625, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 981, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 1023, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 1022, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30002, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30005, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30004, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30100, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30101, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30103, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30135, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30173, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30170, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30181, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30258, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30287, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30284, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 1077, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 1076, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30328, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30317, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30324, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30310, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30371, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30359, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 1094, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 1095, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30423, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30424, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30478, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30499, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30502, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30501, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30504, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30513, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30503, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30500, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30597, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30599, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30598, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30600, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30648, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30649, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30650, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30789, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30874, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30856, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30857, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30858, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30916, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30891, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30893, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30892, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30894, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30895, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30955, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30958, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30971, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 31009, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 31010, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 31005, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 31054, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 31055, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 31084, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 31102, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31101, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31120, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31149, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31181, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31193, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31192, 10, 6, 1);			
				}
			case 478:
				{
					//nothing		
				}
			case 479:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd4 = GetRandomInt(1,480);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 53, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 110, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 109, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 117, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 158, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 181, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 229, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 314, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 344, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 393, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 400, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 518, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 534, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 618, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 626, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 600, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 566, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 564, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 565, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 645, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 720, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 759, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 762, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 779, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 819, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 847, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 824, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 877, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 917, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 5625, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 981, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 1023, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 1022, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30002, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30005, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30004, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30100, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30101, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30103, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30135, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30173, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30170, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30181, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30258, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30287, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30284, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 1077, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 1076, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30328, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30317, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30324, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30310, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30371, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30359, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 1094, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 1095, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30423, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30424, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30478, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30499, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30502, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30501, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30504, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30513, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30503, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30500, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30597, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30599, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30598, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30600, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30648, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30649, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30650, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30789, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30874, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30856, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30857, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30858, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30916, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30891, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30893, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30892, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30894, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30895, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30955, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30958, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30971, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 31009, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 31010, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 31005, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 31054, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 31055, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 31084, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 31102, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31101, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31120, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31149, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31181, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31193, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31192, 10, 6, 1);			
				}
			case 478:
				{
					//nothing		
				}
			case 479:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
			int rnd5 = GetRandomInt(1,480);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 53, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 110, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 109, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 117, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 158, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 181, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 229, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 314, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 344, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 393, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 400, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 518, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 534, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 618, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 631, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 626, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 600, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 566, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 564, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 565, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 646, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 647, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 645, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 720, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 734, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 759, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 762, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 783, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 779, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 819, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 815, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 847, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 824, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 877, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 917, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 925, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 5625, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 949, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 981, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 986, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 1023, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 1022, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30002, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30005, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30004, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30056, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30100, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30101, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30103, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30135, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30173, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30170, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30181, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30258, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30287, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30284, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30212, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 1077, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 1076, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30328, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30317, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30324, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30310, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30316, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30371, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30359, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30373, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 1094, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 1095, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30423, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30424, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30478, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30481, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30499, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30502, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30501, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30504, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30513, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30503, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30500, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30550, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30597, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30599, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30598, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30600, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 30629, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 30648, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 30649, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 30650, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 30789, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 30873, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 30874, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 30856, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 30857, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 30858, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 30916, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 30891, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 30893, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 30892, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 30894, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 30895, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 30955, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 30958, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 30971, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 30977, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 30978, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 31009, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 31010, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 31005, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 31054, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 31055, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 31084, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 31102, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 31101, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 31094, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 31120, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 31149, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 31181, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 159:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 454:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 455:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 457:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 458:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 459:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 460:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 461:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 462:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 463:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 464:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 465:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 466:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 467:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 468:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 469:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 470:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 471:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 472:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 473:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 474:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 475:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 476:
				{
					CreateHat(client, 31193, 10, 6, 1);			
				}
			case 477:
				{
					CreateHat(client, 31192, 10, 6, 1);			
				}
			case 478:
				{
					//nothing		
				}
			case 479:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 480:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			int rnd3 = GetRandomInt(1,456);
			switch (rnd3)
			{
			case 1:
				{
					CreateHat(client, 55, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 108, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 103, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 147, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 180, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 223, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 319, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 337, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 361, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 397, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 437, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 459, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 462, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 483, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 521, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 602, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 622, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 629, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 559, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 560, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 558, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 637, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 763, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 782, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 789, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 841, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 825, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 879, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 872, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 919, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5623, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 977, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 1030, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 30007, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30047, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30009, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30072, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30133, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30128, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30132, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30123, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30125, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30183, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30182, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30260, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30301, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30261, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30283, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30256, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30353, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30360, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30411, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30404, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30389, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30405, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30467, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30476, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30512, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30506, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30507, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30505, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30606, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30602, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30603, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30631, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30651, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30753, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30752, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30777, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30775, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30798, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30797, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30827, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30848, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30988, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30989, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 31015, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 31014, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 31016, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 31048, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 31073, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 31072, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 31110, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 31109, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 31124, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31194, 10, 6, 1);			
				}
			case 454:
				{
					//blank			
				}
			case 455:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}				
			}
			int rnd4 = GetRandomInt(1,456);
			switch (rnd4)
			{
			case 1:
				{
					CreateHat(client, 55, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 108, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 103, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 147, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 180, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 223, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 319, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 337, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 361, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 397, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 437, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 459, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 462, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 483, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 521, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 602, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 622, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 629, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 559, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 560, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 558, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 637, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 763, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 782, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 789, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 841, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 825, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 879, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 872, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 919, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5623, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 977, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 1030, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 30007, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30047, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30009, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30072, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30133, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30128, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30132, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30123, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30125, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30183, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30182, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30260, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30301, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30261, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30283, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30256, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30353, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30360, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30411, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30404, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30389, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30405, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30467, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30476, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30512, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30506, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30507, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30505, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30606, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30602, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30603, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30631, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30651, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30753, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30752, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30777, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30775, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30798, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30797, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30827, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30848, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30988, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30989, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 31015, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 31014, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 31016, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 31048, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 31073, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 31072, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 31110, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 31109, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 31124, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31194, 10, 6, 1);			
				}
			case 454:
				{
					//blank			
				}
			case 455:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}				
			}
			int rnd5 = GetRandomInt(1,456);
			switch (rnd5)
			{
			case 1:
				{
					CreateHat(client, 55, 10, 6, 1);			
				}
			case 2:
				{
					CreateHat(client, 108, 10, 6, 1);			
				}
			case 3:
				{
					CreateHat(client, 103, 10, 6, 1);			
				}
			case 4:
				{
					CreateHat(client, 147, 10, 6, 1);			
				}
			case 5:
				{
					CreateHat(client, 180, 10, 6, 1);			
				}
			case 6:
				{
					CreateHat(client, 223, 10, 6, 1);			
				}
			case 7:
				{
					CreateHat(client, 319, 10, 6, 1);			
				}
			case 8:
				{
					CreateHat(client, 337, 10, 6, 1);			
				}
			case 9:
				{
					CreateHat(client, 361, 10, 6, 1);			
				}
			case 10:
				{
					CreateHat(client, 397, 10, 6, 1);			
				}
			case 11:
				{
					CreateHat(client, 388, 10, 6, 1);			
				}
			case 12:
				{
					CreateHat(client, 437, 10, 6, 1);			
				}
			case 13:
				{
					CreateHat(client, 459, 10, 6, 1);			
				}
			case 14:
				{
					CreateHat(client, 462, 10, 6, 1);			
				}
			case 15:
				{
					CreateHat(client, 483, 10, 6, 1);			
				}
			case 16:
				{
					CreateHat(client, 521, 10, 6, 1);			
				}
			case 17:
				{
					CreateHat(client, 602, 10, 6, 1);			
				}
			case 18:
				{
					CreateHat(client, 622, 10, 6, 1);			
				}
			case 19:
				{
					CreateHat(client, 629, 10, 6, 1);			
				}
			case 20:
				{
					CreateHat(client, 559, 10, 6, 1);			
				}
			case 21:
				{
					CreateHat(client, 560, 10, 6, 1);			
				}
			case 22:
				{
					CreateHat(client, 558, 10, 6, 1);			
				}
			case 23:
				{
					CreateHat(client, 639, 10, 6, 1);			
				}
			case 24:
				{
					CreateHat(client, 637, 10, 6, 1);			
				}
			case 25:
				{
					CreateHat(client, 766, 10, 6, 1);			
				}
			case 26:
				{
					CreateHat(client, 763, 10, 6, 1);			
				}
			case 27:
				{
					CreateHat(client, 782, 10, 6, 1);			
				}
			case 28:
				{
					CreateHat(client, 814, 10, 6, 1);			
				}
			case 29:
				{
					CreateHat(client, 789, 10, 6, 1);			
				}
			case 30:
				{
					CreateHat(client, 841, 10, 6, 1);			
				}
			case 31:
				{
					CreateHat(client, 825, 10, 6, 1);			
				}
			case 32:
				{
					CreateHat(client, 879, 10, 6, 1);			
				}
			case 33:
				{
					CreateHat(client, 872, 10, 6, 1);			
				}
			case 34:
				{
					CreateHat(client, 936, 10, 6, 1);			
				}
			case 35:
				{
					CreateHat(client, 919, 10, 6, 1);			
				}
			case 36:
				{
					CreateHat(client, 5623, 10, 6, 1);			
				}
			case 37:
				{
					CreateHat(client, 977, 10, 6, 1);			
				}
			case 38:
				{
					CreateHat(client, 1030, 10, 6, 1);			
				}
			case 39:
				{
					CreateHat(client, 1029, 10, 6, 1);			
				}
			case 40:
				{
					CreateHat(client, 30007, 10, 6, 1);			
				}
			case 41:
				{
					CreateHat(client, 30047, 10, 6, 1);			
				}
			case 42:
				{
					CreateHat(client, 30009, 10, 6, 1);			
				}
			case 43:
				{
					CreateHat(client, 30072, 10, 6, 1);			
				}
			case 44:
				{
					CreateHat(client, 30069, 10, 6, 1);			
				}
			case 45:
				{
					CreateHat(client, 30133, 10, 6, 1);			
				}
			case 46:
				{
					CreateHat(client, 30128, 10, 6, 1);			
				}
			case 47:
				{
					CreateHat(client, 30132, 10, 6, 1);			
				}
			case 48:
				{
					CreateHat(client, 30123, 10, 6, 1);			
				}
			case 49:
				{
					CreateHat(client, 30125, 10, 6, 1);			
				}
			case 50:
				{
					CreateHat(client, 30085, 10, 6, 1);			
				}
			case 51:
				{
					CreateHat(client, 30183, 10, 6, 1);			
				}
			case 52:
				{
					CreateHat(client, 30189, 10, 6, 1);			
				}
			case 53:
				{
					CreateHat(client, 30182, 10, 6, 1);			
				}
			case 54:
				{
					CreateHat(client, 30260, 10, 6, 1);			
				}
			case 55:
				{
					CreateHat(client, 30301, 10, 6, 1);			
				}
			case 56:
				{
					CreateHat(client, 30261, 10, 6, 1);			
				}
			case 57:
				{
					CreateHat(client, 30283, 10, 6, 1);			
				}
			case 58:
				{
					CreateHat(client, 30256, 10, 6, 1);			
				}
			case 59:
				{
					CreateHat(client, 30195, 10, 6, 1);			
				}
			case 60:
				{
					CreateHat(client, 30353, 10, 6, 1);			
				}
			case 61:
				{
					CreateHat(client, 30360, 10, 6, 1);			
				}
			case 62:
				{
					CreateHat(client, 30375, 10, 6, 1);			
				}
			case 63:
				{
					CreateHat(client, 30411, 10, 6, 1);			
				}
			case 64:
				{
					CreateHat(client, 30404, 10, 6, 1);			
				}
			case 65:
				{
					CreateHat(client, 30389, 10, 6, 1);			
				}
			case 66:
				{
					CreateHat(client, 30405, 10, 6, 1);			
				}
			case 67:
				{
					CreateHat(client, 30467, 10, 6, 1);			
				}
			case 68:
				{
					CreateHat(client, 30476, 10, 6, 1);			
				}
			case 69:
				{
					CreateHat(client, 30512, 10, 6, 1);			
				}
			case 70:
				{
					CreateHat(client, 30506, 10, 6, 1);			
				}
			case 71:
				{
					CreateHat(client, 30507, 10, 6, 1);			
				}
			case 72:
				{
					CreateHat(client, 30505, 10, 6, 1);			
				}
			case 73:
				{
					CreateHat(client, 30606, 10, 6, 1);			
				}
			case 74:
				{
					CreateHat(client, 30602, 10, 6, 1);			
				}
			case 75:
				{
					CreateHat(client, 30603, 10, 6, 1);			
				}
			case 76:
				{
					CreateHat(client, 30631, 10, 6, 1);			
				}
			case 77:
				{
					CreateHat(client, 30651, 10, 6, 1);			
				}
			case 78:
				{
					CreateHat(client, 30728, 10, 6, 1);			
				}
			case 79:
				{
					CreateHat(client, 30733, 10, 6, 1);			
				}
			case 80:
				{
					CreateHat(client, 30753, 10, 6, 1);			
				}
			case 81:
				{
					CreateHat(client, 30752, 10, 6, 1);			
				}
			case 82:
				{
					CreateHat(client, 30777, 10, 6, 1);			
				}
			case 83:
				{
					CreateHat(client, 30775, 10, 6, 1);			
				}
			case 84:
				{
					CreateHat(client, 30798, 10, 6, 1);			
				}
			case 85:
				{
					CreateHat(client, 30797, 10, 6, 1);			
				}
			case 86:
				{
					CreateHat(client, 30827, 10, 6, 1);			
				}
			case 87:
				{
					CreateHat(client, 30831, 10, 6, 1);			
				}
			case 88:
				{
					CreateHat(client, 30848, 10, 6, 1);			
				}
			case 89:
				{
					CreateHat(client, 30884, 10, 6, 1);			
				}
			case 90:
				{
					CreateHat(client, 30988, 10, 6, 1);			
				}
			case 91:
				{
					CreateHat(client, 30989, 10, 6, 1);			
				}
			case 92:
				{
					CreateHat(client, 31015, 10, 6, 1);			
				}
			case 93:
				{
					CreateHat(client, 31014, 10, 6, 1);			
				}
			case 94:
				{
					CreateHat(client, 31016, 10, 6, 1);			
				}
			case 95:
				{
					CreateHat(client, 31033, 10, 6, 1);			
				}
			case 96:
				{
					CreateHat(client, 31048, 10, 6, 1);			
				}
			case 97:
				{
					CreateHat(client, 31073, 10, 6, 1);			
				}
			case 98:
				{
					CreateHat(client, 31072, 10, 6, 1);			
				}
			case 99:
				{
					CreateHat(client, 31110, 10, 6, 1);			
				}
			case 100:
				{
					CreateHat(client, 31109, 10, 6, 1);			
				}
			case 101:
				{
					CreateHat(client, 31124, 10, 6, 1);			
				}
			case 102:
				{
					CreateHat(client, 31163, 10, 6, 1);			
				}
			case 103:
				{
					CreateHat(client, 125, 10, 6, 1);			
				}
			case 104:
				{
					CreateHat(client, 116, 10, 6, 1);			
				}
			case 105:
				{
					CreateHat(client, 115, 10, 6, 1);			
				}
			case 106:
				{
					CreateHat(client, 126, 10, 6, 1);			
				}
			case 107:
				{
					CreateHat(client, 139, 10, 6, 1);			
				}
			case 108:
				{
					CreateHat(client, 137, 10, 6, 1);			
				}
			case 109:
				{
					CreateHat(client, 135, 10, 6, 1);			
				}
			case 110:
				{
					CreateHat(client, 138, 10, 6, 1);			
				}
			case 111:
				{
					CreateHat(client, 136, 10, 6, 1);			
				}
			case 112:
				{
					CreateHat(client, 134, 10, 6, 1);			
				}
			case 113:
				{
					CreateHat(client, 162, 10, 6, 1);			
				}
			case 114:
				{
					CreateHat(client, 166, 10, 6, 1);			
				}
			case 115:
				{
					CreateHat(client, 165, 10, 6, 1);			
				}
			case 116:
				{
					CreateHat(client, 164, 10, 6, 1);			
				}
			case 117:
				{
					CreateHat(client, 170, 10, 6, 1);			
				}
			case 118:
				{
					CreateHat(client, 143, 10, 6, 1);			
				}
			case 119:
				{
					CreateHat(client, 189, 10, 6, 1);			
				}
			case 120:
				{
					CreateHat(client, 260, 10, 6, 1);			
				}
			case 121:
				{
					CreateHat(client, 263, 10, 6, 1);			
				}
			case 122:
				{
					CreateHat(client, 261, 10, 6, 1);			
				}
			case 123:
				{
					CreateHat(client, 242, 10, 6, 1);			
				}
			case 124:
				{
					CreateHat(client, 243, 10, 6, 1);			
				}
			case 125:
				{
					CreateHat(client, 244, 10, 6, 1);			
				}
			case 126:
				{
					CreateHat(client, 245, 10, 6, 1);			
				}
			case 127:
				{
					CreateHat(client, 262, 10, 6, 1);			
				}
			case 128:
				{
					CreateHat(client, 252, 10, 6, 1);			
				}
			case 129:
				{
					CreateHat(client, 279, 10, 6, 1);			
				}
			case 130:
				{
					CreateHat(client, 268, 10, 6, 1);			
				}
			case 131:
				{
					CreateHat(client, 269, 10, 6, 1);			
				}
			case 132:
				{
					CreateHat(client, 270, 10, 6, 1);			
				}
			case 133:
				{
					CreateHat(client, 271, 10, 6, 1);			
				}
			case 134:
				{
					CreateHat(client, 272, 10, 6, 1);			
				}
			case 135:
				{
					CreateHat(client, 273, 10, 6, 1);			
				}
			case 136:
				{
					CreateHat(client, 274, 10, 6, 1);			
				}
			case 137:
				{
					CreateHat(client, 275, 10, 6, 1);			
				}
			case 138:
				{
					CreateHat(client, 276, 10, 6, 1);			
				}
			case 139:
				{
					CreateHat(client, 277, 10, 6, 1);			
				}
			case 140:
				{
					CreateHat(client, 291, 10, 6, 1);			
				}
			case 141:
				{
					CreateHat(client, 278, 10, 6, 1);			
				}
			case 142:
				{
					CreateHat(client, 287, 10, 6, 1);			
				}
			case 143:
				{
					CreateHat(client, 289, 10, 6, 1);			
				}
			case 144:
				{
					CreateHat(client, 299, 10, 6, 1);			
				}
			case 145:
				{
					CreateHat(client, 296, 10, 6, 1);			
				}
			case 146:
				{
					CreateHat(client, 332, 10, 6, 1);			
				}
			case 147:
				{
					CreateHat(client, 333, 10, 6, 1);			
				}
			case 148:
				{
					CreateHat(client, 334, 10, 6, 1);			
				}
			case 149:
				{
					CreateHat(client, 341, 10, 6, 1);			
				}
			case 150:
				{
					CreateHat(client, 1899, 10, 6, 1);			
				}
			case 151:
				{
					CreateHat(client, 345, 10, 6, 1);			
				}
			case 152:
				{
					CreateHat(client, 408, 10, 6, 1);			
				}
			case 153:
				{
					CreateHat(client, 409, 10, 6, 1);			
				}
			case 154:
				{
					CreateHat(client, 410, 10, 6, 1);			
				}
			case 155:
				{
					CreateHat(client, 420, 10, 6, 1);			
				}
			case 156:
				{
					CreateHat(client, 422, 10, 6, 1);			
				}
			case 157:
				{
					CreateHat(client, 432, 10, 6, 1);			
				}
			case 158:
				{
					CreateHat(client, 302, 10, 6, 1);			
				}
			case 160:
				{
					CreateHat(client, 470, 10, 6, 1);			
				}
			case 161:
				{
					CreateHat(client, 473, 10, 6, 1);			
				}
			case 162:
				{
					CreateHat(client, 343, 10, 6, 1);			
				}
			case 163:
				{
					CreateHat(client, 471, 10, 6, 1);			
				}
			case 164:
				{
					CreateHat(client, 492, 10, 6, 1);			
				}
			case 165:
				{
					CreateHat(client, 486, 10, 6, 1);			
				}
			case 166:
				{
					CreateHat(client, 443, 10, 6, 1);			
				}
			case 167:
				{
					CreateHat(client, 523, 10, 6, 1);			
				}
			case 168:
				{
					CreateHat(client, 522, 10, 6, 1);			
				}
			case 169:
				{
					CreateHat(client, 537, 10, 6, 1);			
				}
			case 170:
				{
					CreateHat(client, 538, 10, 6, 1);			
				}
			case 171:
				{
					CreateHat(client, 624, 10, 6, 1);			
				}
			case 172:
				{
					CreateHat(client, 619, 10, 6, 1);			
				}
			case 173:
				{
					CreateHat(client, 598, 10, 6, 1);			
				}
			case 174:
				{
					CreateHat(client, 541, 10, 6, 1);			
				}
			case 175:
				{
					CreateHat(client, 623, 10, 6, 1);			
				}
			case 176:
				{
					CreateHat(client, 614, 10, 6, 1);			
				}
			case 177:
				{
					CreateHat(client, 611, 10, 6, 1);			
				}
			case 178:
				{
					CreateHat(client, 583, 10, 6, 1);			
				}
			case 179:
				{
					CreateHat(client, 584, 10, 6, 1);			
				}
			case 180:
				{
					CreateHat(client, 581, 10, 6, 1);			
				}
			case 181:
				{
					CreateHat(client, 582, 10, 6, 1);			
				}
			case 182:
				{
					CreateHat(client, 586, 10, 6, 1);			
				}
			case 183:
				{
					CreateHat(client, 634, 10, 6, 1);			
				}
			case 184:
				{
					CreateHat(client, 640, 10, 6, 1);			
				}
			case 185:
				{
					CreateHat(client, 666, 10, 6, 1);			
				}
			case 186:
				{
					CreateHat(client, 671, 10, 6, 1);			
				}
			case 187:
				{
					CreateHat(client, 592, 10, 6, 1);			
				}
			case 188:
				{
					CreateHat(client, 636, 10, 6, 1);			
				}
			case 189:
				{
					CreateHat(client, 675, 10, 6, 1);			
				}
			case 190:
				{
					CreateHat(client, 668, 10, 6, 1);			
				}
			case 191:
				{
					CreateHat(client, 667, 10, 6, 1);			
				}
			case 192:
				{
					CreateHat(client, 655, 10, 6, 1);			
				}
			case 193:
				{
					CreateHat(client, 717, 10, 6, 1);			
				}
			case 194:
				{
					CreateHat(client, 704, 10, 6, 1);			
				}
			case 195:
				{
					CreateHat(client, 702, 10, 6, 1);			
				}
			case 196:
				{
					CreateHat(client, 718, 10, 6, 1);			
				}
			case 197:
				{
					CreateHat(client, 5075, 10, 6, 1);			
				}
			case 198:
				{
					CreateHat(client, 711, 10, 6, 1);			
				}
			case 199:
				{
					CreateHat(client, 712, 10, 6, 1);			
				}
			case 200:
				{
					CreateHat(client, 713, 10, 6, 1);			
				}
			case 201:
				{
					CreateHat(client, 756, 10, 6, 1);			
				}
			case 202:
				{
					CreateHat(client, 767, 10, 6, 1);			
				}
			case 203:
				{
					CreateHat(client, 5606, 10, 6, 1);			
				}
			case 204:
				{
					CreateHat(client, 738, 10, 6, 1);			
				}
			case 205:
				{
					CreateHat(client, 774, 10, 6, 1);			
				}
			case 206:
				{
					CreateHat(client, 744, 10, 6, 1);			
				}
			case 207:
				{
					CreateHat(client, 785, 10, 6, 1);			
				}
			case 208:
				{
					CreateHat(client, 818, 10, 6, 1);			
				}
			case 209:
				{
					CreateHat(client, 725, 10, 6, 1);			
				}
			case 210:
				{
					CreateHat(client, 733, 10, 6, 1);			
				}
			case 211:
				{
					CreateHat(client, 855, 10, 6, 1);			
				}
			case 212:
				{
					CreateHat(client, 864, 10, 6, 1);			
				}
			case 213:
				{
					CreateHat(client, 868, 10, 6, 1);			
				}
			case 214:
				{
					CreateHat(client, 865, 10, 6, 1);			
				}
			case 215:
				{
					CreateHat(client, 873, 10, 6, 1);			
				}
			case 216:
				{
					CreateHat(client, 927, 10, 6, 1);			
				}
			case 217:
				{
					CreateHat(client, 920, 10, 6, 1);			
				}
			case 218:
				{
					CreateHat(client, 921, 10, 6, 1);			
				}
			case 219:
				{
					CreateHat(client, 934, 10, 6, 1);			
				}
			case 220:
				{
					CreateHat(client, 940, 10, 6, 1);			
				}
			case 221:
				{
					CreateHat(client, 869, 10, 6, 1);			
				}
			case 222:
				{
					CreateHat(client, 941, 10, 6, 1);			
				}
			case 223:
				{
					CreateHat(client, 929, 10, 6, 1);			
				}
			case 224:
				{
					CreateHat(client, 943, 10, 6, 1);			
				}
			case 225:
				{
					CreateHat(client, 944, 10, 6, 1);			
				}
			case 226:
				{
					CreateHat(client, 942, 10, 6, 1);			
				}
			case 227:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 228:
				{
					CreateHat(client, 953, 10, 6, 1);			
				}
			case 229:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 230:
				{
					CreateHat(client, 993, 10, 6, 1);			
				}
			case 231:
				{
					CreateHat(client, 994, 10, 6, 1);			
				}
			case 232:
				{
					CreateHat(client, 987, 10, 6, 1);			
				}
			case 233:
				{
					CreateHat(client, 975, 10, 6, 1);			
				}
			case 234:
				{
					CreateHat(client, 1066, 10, 6, 1);			
				}
			case 235:
				{
					CreateHat(client, 870, 10, 6, 1);			
				}
			case 236:
				{
					CreateHat(client, 871, 10, 6, 1);			
				}
			case 237:
				{
					CreateHat(client, 817, 10, 6, 1);			
				}
			case 238:
				{
					CreateHat(client, 816, 10, 6, 1);			
				}
			case 239:
				{
					CreateHat(client, 955, 10, 6, 1);			
				}
			case 240:
				{
					CreateHat(client, 992, 10, 6, 1);			
				}
			case 241:
				{
					CreateHat(client, 984, 10, 6, 1);			
				}
			case 242:
				{
					CreateHat(client, 1011, 10, 6, 1);			
				}
			case 243:
				{
					CreateHat(client, 1014, 10, 6, 1);			
				}
			case 244:
				{
					CreateHat(client, 1024, 10, 6, 1);			
				}
			case 245:
				{
					CreateHat(client, 1025, 10, 6, 1);			
				}
			case 246:
				{
					CreateHat(client, 1033, 10, 6, 1);			
				}
			case 247:
				{
					CreateHat(client, 1034, 10, 6, 1);			
				}
			case 248:
				{
					CreateHat(client, 1035, 10, 6, 1);			
				}
			case 249:
				{
					CreateHat(client, 30000, 10, 6, 1);			
				}
			case 250:
				{
					CreateHat(client, 30003, 10, 6, 1);			
				}
			case 251:
				{
					CreateHat(client, 30001, 10, 6, 1);			
				}
			case 252:
				{
					CreateHat(client, 30006, 10, 6, 1);			
				}
			case 253:
				{
					CreateHat(client, 30008, 10, 6, 1);			
				}
			case 254:
				{
					CreateHat(client, 30018, 10, 6, 1);			
				}
			case 255:
				{
					CreateHat(client, 30058, 10, 6, 1);			
				}
			case 256:
				{
					CreateHat(client, 30066, 10, 6, 1);			
				}
			case 257:
				{
					CreateHat(client, 30068, 10, 6, 1);			
				}
			case 258:
				{
					CreateHat(client, 30067, 10, 6, 1);			
				}
			case 259:
				{
					CreateHat(client, 30065, 10, 6, 1);			
				}
			case 260:
				{
					CreateHat(client, 30104, 10, 6, 1);			
				}
			case 261:
				{
					CreateHat(client, 30140, 10, 6, 1);			
				}
			case 262:
				{
					CreateHat(client, 30119, 10, 6, 1);			
				}
			case 263:
				{
					CreateHat(client, 1067, 10, 6, 1);			
				}
			case 264:
				{
					CreateHat(client, 30175, 10, 6, 1);			
				}
			case 265:
				{
					CreateHat(client, 30177, 10, 6, 1);			
				}
			case 266:
				{
					CreateHat(client, 30206, 10, 6, 1);			
				}
			case 267:
				{
					CreateHat(client, 30255, 10, 6, 1);			
				}
			case 268:
				{
					CreateHat(client, 30215, 10, 6, 1);			
				}
			case 269:
				{
					CreateHat(client, 30302, 10, 6, 1);			
				}
			case 270:
				{
					CreateHat(client, 30278, 10, 6, 1);			
				}
			case 271:
				{
					CreateHat(client, 30252, 10, 6, 1);			
				}
			case 272:
				{
					CreateHat(client, 30300, 10, 6, 1);			
				}
			case 273:
				{
					CreateHat(client, 30297, 10, 6, 1);			
				}
			case 274:
				{
					CreateHat(client, 30295, 10, 6, 1);			
				}
			case 275:
				{
					CreateHat(client, 30214, 10, 6, 1);			
				}
			case 276:
				{
					CreateHat(client, 30198, 10, 6, 1);			
				}
			case 277:
				{
					CreateHat(client, 30289, 10, 6, 1);			
				}
			case 278:
				{
					CreateHat(client, 30234, 10, 6, 1);			
				}
			case 279:
				{
					CreateHat(client, 30274, 10, 6, 1);			
				}
			case 280:
				{
					CreateHat(client, 30254, 10, 6, 1);			
				}
			case 281:
				{
					CreateHat(client, 8938, 10, 6, 1);			
				}
			case 282:
				{
					CreateHat(client, 8367, 10, 6, 1);			
				}
			case 283:
				{
					CreateHat(client, 30313, 10, 6, 1);			
				}
			case 284:
				{
					CreateHat(client, 30307, 10, 6, 1);			
				}
			case 285:
				{
					CreateHat(client, 30329, 10, 6, 1);			
				}
			case 286:
				{
					CreateHat(client, 30309, 10, 6, 1);			
				}
			case 287:
				{
					CreateHat(client, 30306, 10, 6, 1);			
				}
			case 288:
				{
					CreateHat(client, 30362, 10, 6, 1);			
				}
			case 289:
				{
					CreateHat(client, 30352, 10, 6, 1);			
				}
			case 290:
				{
					CreateHat(client, 30357, 10, 6, 1);			
				}
			case 291:
				{
					CreateHat(client, 8395, 10, 6, 1);			
				}
			case 292:
				{
					CreateHat(client, 1096, 10, 6, 1);			
				}
			case 293:
				{
					CreateHat(client, 8396, 10, 6, 1);			
				}
			case 294:
				{
					CreateHat(client, 1122, 10, 6, 1);			
				}
			case 295:
				{
					CreateHat(client, 30397, 10, 6, 1);			
				}
			case 296:
				{
					CreateHat(client, 30414, 10, 6, 1);			
				}
			case 297:
				{
					CreateHat(client, 30413, 10, 6, 1);			
				}
			case 298:
				{
					CreateHat(client, 30425, 10, 6, 1);			
				}
			case 299:
				{
					CreateHat(client, 30422, 10, 6, 1);			
				}
			case 300:
				{
					CreateHat(client, 30469, 10, 6, 1);			
				}
			case 301:
				{
					CreateHat(client, 30473, 10, 6, 1);			
				}
			case 302:
				{
					CreateHat(client, 30484, 10, 6, 1);			
				}
			case 303:
				{
					CreateHat(client, 30497, 10, 6, 1);			
				}
			case 304:
				{
					CreateHat(client, 30498, 10, 6, 1);			
				}
			case 305:
				{
					CreateHat(client, 30536, 10, 6, 1);			
				}
			case 306:
				{
					CreateHat(client, 8584, 10, 6, 1);			
				}
			case 307:
				{
					CreateHat(client, 30571, 10, 6, 1);			
				}
			case 308:
				{
					CreateHat(client, 30567, 10, 6, 1);			
				}
			case 309:
				{
					CreateHat(client, 30569, 10, 6, 1);			
				}
			case 310:
				{
					CreateHat(client, 30546, 10, 6, 1);			
				}
			case 311:
				{
					CreateHat(client, 30542, 10, 6, 1);			
				}
			case 312:
				{
					CreateHat(client, 30551, 10, 6, 1);			
				}
			case 313:
				{
					CreateHat(client, 30549, 10, 6, 1);			
				}
			case 314:
				{
					CreateHat(client, 30559, 10, 6, 1);			
				}
			case 315:
				{
					CreateHat(client, 30576, 10, 6, 1);			
				}
			case 316:
				{
					CreateHat(client, 8633, 10, 6, 1);			
				}
			case 317:
				{
					CreateHat(client, 30607, 10, 6, 1);			
				}
			case 318:
				{
					CreateHat(client, 1158, 10, 6, 1);			
				}
			case 319:
				{
					CreateHat(client, 30640, 10, 6, 1);			
				}
			case 320:
				{
					CreateHat(client, 30643, 10, 6, 1);			
				}
			case 321:
				{
					CreateHat(client, 30623, 10, 6, 1);			
				}
			case 322:
				{
					CreateHat(client, 30646, 10, 6, 1);			
				}
			case 323:
				{
					CreateHat(client, 30670, 10, 6, 1);			
				}
			case 324:
				{
					CreateHat(client, 30647, 10, 6, 1);			
				}
			case 325:
				{
					CreateHat(client, 30669, 10, 6, 1);			
				}
			case 326:
				{
					CreateHat(client, 30658, 10, 6, 1);			
				}
			case 327:
				{
					CreateHat(client, 30706, 10, 6, 1);			
				}
			case 328:
				{
					CreateHat(client, 30700, 10, 6, 1);			
				}
			case 329:
				{
					CreateHat(client, 30693, 10, 6, 1);			
				}
			case 330:
				{
					CreateHat(client, 30704, 10, 6, 1);			
				}
			case 331:
				{
					CreateHat(client, 9046, 10, 6, 1);			
				}
			case 332:
				{
					CreateHat(client, 9045, 10, 6, 1);			
				}
			case 333:
				{
					CreateHat(client, 9048, 10, 6, 1);			
				}
			case 334:
				{
					CreateHat(client, 9307, 10, 6, 1);			
				}
			case 335:
				{
					CreateHat(client, 30740, 10, 6, 1);			
				}
			case 336:
				{
					CreateHat(client, 30738, 10, 6, 1);			
				}
			case 337:
				{
					CreateHat(client, 30722, 10, 6, 1);			
				}
			case 338:
				{
					CreateHat(client, 30726, 10, 6, 1);			
				}
			case 339:
				{
					CreateHat(client, 30746, 10, 6, 1);			
				}
			case 340:
				{
					CreateHat(client, 30748, 10, 6, 1);			
				}
			case 341:
				{
					CreateHat(client, 30743, 10, 6, 1);			
				}
			case 342:
				{
					CreateHat(client, 30768, 10, 6, 1);			
				}
			case 343:
				{
					CreateHat(client, 1171, 10, 6, 1);			
				}
			case 344:
				{
					CreateHat(client, 9229, 10, 6, 1);			
				}
			case 345:
				{
					CreateHat(client, 9592, 10, 6, 1);			
				}
			case 346:
				{
					CreateHat(client, 30759, 10, 6, 1);			
				}
			case 347:
				{
					CreateHat(client, 30757, 10, 6, 1);			
				}
			case 348:
				{
					CreateHat(client, 1164, 10, 6, 1);			
				}
			case 349:
				{
					CreateHat(client, 1169, 10, 6, 1);			
				}
			case 350:
				{
					CreateHat(client, 1170, 10, 6, 1);			
				}
			case 351:
				{
					CreateHat(client, 9231, 10, 6, 1);			
				}
			case 352:
				{
					CreateHat(client, 9232, 10, 6, 1);			
				}
			case 353:
				{
					CreateHat(client, 9233, 10, 6, 1);			
				}
			case 354:
				{
					CreateHat(client, 30808, 10, 6, 1);			
				}
			case 355:
				{
					CreateHat(client, 30814, 10, 6, 1);			
				}
			case 356:
				{
					CreateHat(client, 30810, 10, 6, 1);			
				}
			case 357:
				{
					CreateHat(client, 30801, 10, 6, 1);			
				}
			case 358:
				{
					CreateHat(client, 30796, 10, 6, 1);			
				}
			case 359:
				{
					CreateHat(client, 1173, 10, 6, 1);			
				}
			case 360:
				{
					CreateHat(client, 9297, 10, 6, 1);			
				}
			case 361:
				{
					CreateHat(client, 9296, 10, 6, 1);			
				}
			case 362:
				{
					CreateHat(client, 9298, 10, 6, 1);			
				}
			case 363:
				{
					CreateHat(client, 9299, 10, 6, 1);			
				}
			case 364:
				{
					CreateHat(client, 30838, 10, 6, 1);			
				}
			case 365:
				{
					CreateHat(client, 30829, 10, 6, 1);			
				}
			case 366:
				{
					CreateHat(client, 30833, 10, 6, 1);			
				}
			case 367:
				{
					CreateHat(client, 9308, 10, 6, 1);			
				}
			case 368:
				{
					CreateHat(client, 9510, 10, 6, 1);			
				}
			case 369:
				{
					CreateHat(client, 1177, 10, 6, 1);			
				}
			case 370:
				{
					CreateHat(client, 9515, 10, 6, 1);			
				}
			case 371:
				{
					CreateHat(client, 30868, 10, 6, 1);			
				}
			case 372:
				{
					CreateHat(client, 9591, 10, 6, 1);			
				}
			case 373:
				{
					CreateHat(client, 9613, 10, 6, 1);			
				}
			case 374:
				{
					CreateHat(client, 9632, 10, 6, 1);			
				}
			case 375:
				{
					CreateHat(client, 9631, 10, 6, 1);			
				}
			case 376:
				{
					CreateHat(client, 9630, 10, 6, 1);			
				}
			case 377:
				{
					CreateHat(client, 30879, 10, 6, 1);			
				}
			case 378:
				{
					CreateHat(client, 30881, 10, 6, 1);			
				}
			case 379:
				{
					CreateHat(client, 30887, 10, 6, 1);			
				}
			case 380:
				{
					CreateHat(client, 30882, 10, 6, 1);			
				}
			case 381:
				{
					CreateHat(client, 1186, 10, 6, 1);			
				}
			case 382:
				{
					CreateHat(client, 30915, 10, 6, 1);			
				}
			case 383:
				{
					CreateHat(client, 30880, 10, 6, 1);			
				}
			case 384:
				{
					CreateHat(client, 30878, 10, 6, 1);			
				}
			case 385:
				{
					CreateHat(client, 1185, 10, 6, 1);			
				}
			case 386:
				{
					CreateHat(client, 30883, 10, 6, 1);			
				}
			case 387:
				{
					CreateHat(client, 9720, 10, 6, 1);			
				}
			case 388:
				{
					CreateHat(client, 9721, 10, 6, 1);			
				}
			case 389:
				{
					CreateHat(client, 9722, 10, 6, 1);			
				}
			case 390:
				{
					CreateHat(client, 9731, 10, 6, 1);			
				}
			case 391:
				{
					CreateHat(client, 9732, 10, 6, 1);			
				}
			case 392:
				{
					CreateHat(client, 30923, 10, 6, 1);			
				}
			case 393:
				{
					CreateHat(client, 30928, 10, 6, 1);			
				}
			case 394:
				{
					CreateHat(client, 30929, 10, 6, 1);			
				}
			case 395:
				{
					CreateHat(client, 30972, 10, 6, 1);			
				}
			case 396:
				{
					CreateHat(client, 30974, 10, 6, 1);			
				}
			case 397:
				{
					CreateHat(client, 30975, 10, 6, 1);			
				}
			case 398:
				{
					CreateHat(client, 30976, 10, 6, 1);			
				}
			case 399:
				{
					CreateHat(client, 9848, 10, 6, 1);			
				}
			case 400:
				{
					CreateHat(client, 9912, 10, 6, 1);			
				}
			case 401:
				{
					CreateHat(client, 9911, 10, 6, 1);			
				}
			case 402:
				{
					CreateHat(client, 9910, 10, 6, 1);			
				}
			case 403:
				{
					CreateHat(client, 9909, 10, 6, 1);			
				}
			case 404:
				{
					CreateHat(client, 9908, 10, 6, 1);			
				}
			case 405:
				{
					CreateHat(client, 9907, 10, 6, 1);			
				}
			case 406:
				{
					CreateHat(client, 30997, 10, 6, 1);			
				}
			case 407:
				{
					CreateHat(client, 30998, 10, 6, 1);			
				}
			case 408:
				{
					CreateHat(client, 30996, 10, 6, 1);			
				}
			case 409:
				{
					CreateHat(client, 31020, 10, 6, 1);			
				}
			case 410:
				{
					CreateHat(client, 31019, 10, 6, 1);			
				}
			case 411:
				{
					CreateHat(client, 31018, 10, 6, 1);			
				}
			case 412:
				{
					CreateHat(client, 31036, 10, 6, 1);			
				}
			case 413:
				{
					CreateHat(client, 31058, 10, 6, 1);			
				}
			case 414:
				{
					CreateHat(client, 31060, 10, 6, 1);			
				}
			case 415:
				{
					CreateHat(client, 31062, 10, 6, 1);			
				}
			case 416:
				{
					CreateHat(client, 31063, 10, 6, 1);			
				}
			case 417:
				{
					CreateHat(client, 31059, 10, 6, 1);			
				}
			case 418:
				{
					CreateHat(client, 31061, 10, 6, 1);			
				}
			case 419:
				{
					CreateHat(client, 31085, 10, 6, 1);			
				}
			case 420:
				{
					CreateHat(client, 31092, 10, 6, 1);			
				}
			case 421:
				{
					CreateHat(client, 31091, 10, 6, 1);			
				}
			case 422:
				{
					CreateHat(client, 31088, 10, 6, 1);			
				}
			case 423:
				{
					CreateHat(client, 31093, 10, 6, 1);			
				}
			case 424:
				{
					CreateHat(client, 31090, 10, 6, 1);			
				}
			case 425:
				{
					CreateHat(client, 31086, 10, 6, 1);			
				}
			case 426:
				{
					CreateHat(client, 31089, 10, 6, 1);			
				}
			case 427:
				{
					CreateHat(client, 31087, 10, 6, 1);			
				}
			case 428:
				{
					CreateHat(client, 31104, 10, 6, 1);			
				}
			case 429:
				{
					CreateHat(client, 31103, 10, 6, 1);			
				}
			case 430:
				{
					CreateHat(client, 31105, 10, 6, 1);			
				}
			case 431:
				{
					CreateHat(client, 31129, 10, 6, 1);			
				}
			case 432:
				{
					CreateHat(client, 31152, 10, 6, 1);			
				}
			case 433:
				{
					CreateHat(client, 31126, 10, 6, 1);			
				}
			case 434:
				{
					CreateHat(client, 31134, 10, 6, 1);			
				}
			case 435:
				{
					CreateHat(client, 31127, 10, 6, 1);			
				}
			case 436:
				{
					CreateHat(client, 31135, 10, 6, 1);			
				}
			case 437:
				{
					CreateHat(client, 31128, 10, 6, 1);			
				}
			case 438:
				{
					CreateHat(client, 31125, 10, 6, 1);			
				}
			case 439:
				{
					CreateHat(client, 31130, 10, 6, 1);			
				}
			case 440:
				{
					CreateHat(client, 31136, 10, 6, 1);			
				}
			case 441:
				{
					CreateHat(client, 31131, 10, 6, 1);			
				}
			case 442:
				{
					CreateHat(client, 31132, 10, 6, 1);			
				}
			case 443:
				{
					CreateHat(client, 31164, 10, 6, 1);			
				}
			case 444:
				{
					CreateHat(client, 31172, 10, 6, 1);			
				}
			case 445:
				{
					CreateHat(client, 31167, 10, 6, 1);			
				}
			case 446:
				{
					CreateHat(client, 31165, 10, 6, 1);			
				}
			case 447:
				{
					CreateHat(client, 31170, 10, 6, 1);			
				}
			case 448:
				{
					CreateHat(client, 31171, 10, 6, 1);			
				}
			case 449:
				{
					CreateHat(client, 31169, 10, 6, 1);			
				}
			case 450:
				{
					CreateHat(client, 31173, 10, 6, 1);			
				}
			case 451:
				{
					CreateHat(client, 31168, 10, 6, 1);			
				}
			case 452:
				{
					CreateHat(client, 31166, 10, 6, 1);			
				}
			case 453:
				{
					CreateHat(client, 31194, 10, 6, 1);			
				}
			case 454:
				{
					//blank			
				}
			case 455:
				{
					CreateHat(client, 31184, 10, 6, 1);			
				}
			case 456:
				{
					CreateHat(client, 31183, 10, 6, 1);			
				}
			}
		}		
	}
	return;
}

bool CreateHat(int client, int itemindex, int level, int quality, int unusual)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	
	if (level !=10)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", GetRandomInt(1,100));
	}

	if (GetRandomInt(1,10) == 1)
	{
		if (quality == 3 || quality == 1 || quality == 13 || quality == 5)
		{
			TF2Attrib_RemoveByDefIndex(hat, 214);
		}
		else
		{
			if (GetRandomInt(1,4) == 1)
			{
				SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
				TF2Attrib_SetByDefIndex(hat, 214, view_as<float>(GetRandomInt(0, 9000)));
			}
		}
	}	

	if (unusual == 0)
	{
		TF2Attrib_RemoveByDefIndex(hat, 134);
	}

	if (unusual == 1)
	{
		if (GetRandomInt(1,10) == 1)
		{
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
			TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,188) + 0.0);
		}
	}

	if (unusual > 1)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityQuality", 5);
		TF2Attrib_SetByDefIndex(hat, 134, unusual + 0.0);
	}	
	
	if(itemindex == 1158 || itemindex == 1173)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityQuality", 5);
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,188) + 0.0);
	}

	if (quality !=5 && quality !=11)
	{
		int rnd4 = GetRandomInt(1,4);
		switch (rnd4)
		{
		case 1:
			{
				SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 1);
			}
		case 2:
			{
				SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 3);
			}
		case 3:
			{
				SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 7);
			}
		}
	}
	
	if (GetRandomInt(1,4) == 1)
	{
		int rndp = GetRandomInt(1,34);
		switch(rndp)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3100495.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8208497.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 1315860.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12377523.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 2960676.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8289918.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15132390.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15185211.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 14204632.0);
				TF2Attrib_SetByDefIndex(hat, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15308410.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8421376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 7511618.0);
				TF2Attrib_SetByDefIndex(hat, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 13595446.0);
				TF2Attrib_SetByDefIndex(hat, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 10843461.0);
				TF2Attrib_SetByDefIndex(hat, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 5322826.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12955537.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 16738740.0);
				TF2Attrib_SetByDefIndex(hat, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6901050.0);
				TF2Attrib_SetByDefIndex(hat, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3329330.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15787660.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8154199.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4345659.0);
				TF2Attrib_SetByDefIndex(hat, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6637376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3874595.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4732984.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12073019.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8400928.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 11049612.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8626083.0);
			}
		case 30:
			{
				TF2Attrib_SetByName(hat, "SPELL: set item tint RGB", 2.0);
			}
		case 31:
			{
				TF2Attrib_SetByName(hat, "SPELL: set item tint RGB", 0.0);
			}
		case 32:
			{
				TF2Attrib_SetByName(hat, "SPELL: set item tint RGB", 1.0);
			}
		case 33:
			{
				TF2Attrib_SetByName(hat, "SPELL: set item tint RGB", 3.0);
			}
		case 34:
			{
				TF2Attrib_SetByName(hat, "SPELL: set item tint RGB", 4.0);
			}
		}
	}
	if (GetRandomInt(1,15) == 1)
	{
		int rndf = GetRandomInt(1,7);
		switch(rndf)
		{
		case 1:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 1.0);
			}
		case 2:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 8421376.0);
			}
		case 3:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 3100495.0);
			}
		case 4:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 5322826.0);
			}
		case 5:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 13595446.0);
			}
		case 6:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 8208497.0);
			}
		case 7:
			{
				TF2Attrib_SetByName(hat, "SPELL: set Halloween footstep type", 2.0);
			}
		}
	}
	if (GetRandomInt(1,20) == 1)
	{
		TF2Attrib_SetByName(hat, "SPELL: Halloween voice modulation", 1.0);
	}

	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
} 

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}
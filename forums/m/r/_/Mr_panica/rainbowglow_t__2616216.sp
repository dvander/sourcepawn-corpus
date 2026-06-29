#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

int g_iPlayerGlowEntity[MAXPLAYERS];
bool g_iPlayerRandomHooked[MAXPLAYERS];
ConVar g_hRainbowCycleRate;

public Plugin myinfo = 
{
	name = "[TF2] Rainbow Glow",
	author = "Pelipoika & Danyas",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnPluginStart()
{	
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_rainbow", Command_Rainbow, ADMFLAG_ROOT);
	
	g_hRainbowCycleRate = CreateConVar("sm_rainbow_cycle_rate", "1.0", "Constrols the speed of which the rainbow glow changes color");
}

public void OnPluginEnd()
{
	int index = -1;
	while ((index = FindEntityByClassname(index, "tf_glow")) != -1)
	{
		char strName[64];
		GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrEqual(strName, "RainbowGlow"))
		{
			AcceptEntityInput(index, "Kill");
		}
	}
}

public Action Command_Rainbow(int client, int argc)
{
	char r[4];
	char g[4];
	char b[4];
	char state[4];
	if (argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rainbow <#userid|name|team> [random / RRRGGGBBB] <0|1>");
		return Plugin_Handled;
	}
	else if (argc > 2)
	{
		GetCmdArg(3, state, sizeof(state));
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	bool randomcolor;
	char color[12];
	GetCmdArg(2, color, sizeof(color));
	
	if(color[0] == 'r' || color[0] == 'R')
	{
//		ReplyToCommand(client, "Random");
		randomcolor = true;
	}
	else
	{	
		strcopy(r, 4, color);
		strcopy(g, 4, color[3]);
		strcopy(b, 4, color[6]);
//		ReplyToCommand(client, "R: %s", r);
//		ReplyToCommand(client, "G: %s", g);
//		ReplyToCommand(client, "B: %s", b);
	}
	
	int iState = state[0] == '1' ? 1 : state[0] == '0' ? 0 : -1 
	//ReplyToCommand(client, "state: %i", iState);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			if(TF2_HasGlow(target_list[i]))
			{
				int iGlow = EntRefToEntIndex(g_iPlayerGlowEntity[target_list[i]]);
				if(iGlow != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(iGlow, "Kill");
					g_iPlayerGlowEntity[target_list[i]] = INVALID_ENT_REFERENCE;
					if(g_iPlayerRandomHooked[target_list[i]])
					{
						SDKUnhook(target_list[i], SDKHook_PreThink, OnPlayerThink);
					}
				}
			}
			else if(iState == -1 || iState == 1)
			{
				int iGlow = TF2_CreateGlow(target_list[i]);
				if(IsValidEntity(iGlow))
				{
					g_iPlayerGlowEntity[target_list[i]] = EntIndexToEntRef(iGlow);
				}
			
				if(randomcolor == false)
				{
					int clr[4];
					clr[0] = StringToInt(r);
					clr[1] = StringToInt(g);
					clr[2] = StringToInt(b);
					clr[3] = 255;
					
					SetVariantColor(clr);
					AcceptEntityInput(iGlow, "SetGlowColor");
				}
				else
				{
					g_iPlayerRandomHooked[target_list[i]] = true;
					SDKHook(target_list[i], SDKHook_PreThink, OnPlayerThink);
				}
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action OnPlayerThink(int client)
{
	int iGlow = EntRefToEntIndex(g_iPlayerGlowEntity[client]);
	if(iGlow != INVALID_ENT_REFERENCE)
	{
		float flRate = g_hRainbowCycleRate.FloatValue;
		
		int color[4];
		color[0] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 0) * 127.5 + 127.5);
		color[1] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 2) * 127.5 + 127.5);
		color[2] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 4) * 127.5 + 127.5);
		color[3] = 255;
		
		SetVariantColor(color);
		AcceptEntityInput(iGlow, "SetGlowColor");
	}
}

stock int TF2_CreateGlow(int iEnt)
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);
	
	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchSpawn(ent);
	
	AcceptEntityInput(ent, "Enable");
	
	//Change name back to old name because we don't need it anymore.
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	return ent;
}

stock bool TF2_HasGlow(int iEnt)
{
	int index = -1;
	while ((index = FindEntityByClassname(index, "tf_glow")) != -1)
	{
		if (GetEntPropEnt(index, Prop_Send, "m_hTarget") == iEnt)
		{
			return true;
		}
	}
	
	return false;
}
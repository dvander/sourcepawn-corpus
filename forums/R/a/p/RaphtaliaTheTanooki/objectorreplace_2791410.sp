#include <sourcemod>
#include <tf2_stocks>
#include <tf_econ_data>
#include <tf2items>
#include <clientprefs>
#include <morecolors>
//#define DEBUG

#pragma semicolon 1
#pragma newdecls optional

#define PLUGIN_VERSION "1.5.6"

public Plugin myinfo = 
{
	name = "[TF2] Conscientious Objector Replacer",
	author = "Peanut",
	description = "Substitui a placa de um player",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/7sRn8Bt"
};

bool g_bReplaceObj[MAXPLAYERS + 1] = { false, ... };
Handle ObjReplacer_cookie;
int rndw[11] = {474, 264, 423, 30758, 1127, 1123, 1071, 1013, 954, 939, 880};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("=======[i see the problem, we're not running TF2 aren't we?]=======");
		return APLRes_Failure;
	}
	return APLRes_Success;
} 

public void OnPluginStart()
{
	CreateConVar("sm_ConObjRep_version", PLUGIN_VERSION, "Rush E", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_replacenow", Command_replacenow, ADMFLAG_GENERIC, "Substitui a placa de um jogador no momento do comando");
	RegAdminCmd("sm_replacealways", Command_replacealways, ADMFLAG_GENERIC, "Ativa substituição ate a proxíma vez que o jogador se conectar");
	RegAdminCmd("sm_objectorban", Command_ObjectorBan, ADMFLAG_GENERIC, "Bane o jogador de utilizar placas com imagens");
	HookEvent("post_inventory_application", Event_InventoryApplication);
	ObjReplacer_cookie = RegClientCookie("ObjReplacer_cookie", "Should the Plugin Replace objector? 1=yes 0=no", CookieAccess_Protected);
	LoadTranslations("common.phrases");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (AreClientCookiesCached(client))
			OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client)
{
	char value[8];
	GetClientCookie(client, ObjReplacer_cookie, value, sizeof(value));

	if (value[0] != '\0')
	{
		g_bReplaceObj[client] = view_as<bool>(StringToInt(value));
	}
	else
	{
		g_bReplaceObj[client] = false;
	}
}

public Action Command_replacenow(int client, int args)
{
	if(args == 0)
	{
		CReplyToCommand(client, "{unique}[O{darkblue}R]{default} Este comando requer um alvo válido");
		return Plugin_Handled;
	}
	char targetArg[MAX_TARGET_LENGTH]; // codigo de adicionar players a uma array
	GetCmdArg(1, targetArg, sizeof(targetArg));

	char targetName[MAX_TARGET_LENGTH];
	int targetList[MAXPLAYERS];
	bool tnIsMl;
	int targetCount = ProcessTargetString(targetArg, client, targetList, MAXPLAYERS,
	COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tnIsMl);

	if(targetCount <= 0) {
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < targetCount; i++) { //função q itera entre os players na lista
	int targetClient = targetList[i];
	int rnd = GetRandomInt(0, 10);
	TF2_RemoveWeaponSlot(targetClient, 2);
	if(rndw[rnd] == 1071)
	{
		TF2Items_GiveWeapon(targetClient, "saxxy", 1071, 69, 8, "150 ; 1 ; 542 ; 0");
	}
	else
	{
		TF2Items_GiveWeapon(targetClient, "saxxy", rndw[rnd], 69, 8, "");
	}
	}
	if(tnIsMl) //texto que será exibido no chat
	{
		CPrintToChatAll("{unique}[O{darkblue}R]{default} Arma de %t substituida", targetName);
	} 
	else 
	{
		CPrintToChatAll("{unique}[O{darkblue}R]{default} Arma de %s substituida", targetName);    
	}
	return Plugin_Handled;
}

stock int TF2Items_GiveWeapon(int client, char[] strName, int Index, int Level = 1, int Quality = 0, char[] strAtt = "")
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);

	TFClassType playerClass = TF2_GetPlayerClass(client);
	char itemClass[64];
	TF2Econ_GetItemClassName(Index, itemClass, sizeof(itemClass));

	TF2Econ_TranslateWeaponEntForClass(itemClass, sizeof(itemClass), playerClass);
	TF2Items_SetClassname(hWeapon, itemClass);
	TF2Items_SetItemIndex(hWeapon, Index);
	TF2Items_SetLevel(hWeapon, Level);
	TF2Items_SetQuality(hWeapon, Quality);

	char strAtts[32][32];
	int iCount = ExplodeString(strAtt, " ; ", strAtts, 32, 32);
	
	if(iCount > 1)
	{
		TF2Items_SetNumAttributes(hWeapon, iCount / 2);
		int z;
		for(int i = 0; i < iCount; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, z, StringToInt(strAtts[i]), StringToFloat(strAtts[i + 1]));
			z++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);

		
	if(hWeapon == INVALID_HANDLE)
		return -1;


	int iEntity = TF2Items_GiveNamedItem(client, hWeapon);

	EquipPlayerWeapon(client, iEntity);
	CloseHandle(hWeapon);
	
	return iEntity;
}

public void OnClientDisconnect(int client)
{
	g_bReplaceObj[client] = false;
}

public Action Command_ObjectorBan(int client, int args)
{
	if(args == 0)
	{
		CReplyToCommand(client, "{unique}[O{darkblue}R]{default}  Este comando requer um alvo válido");
		return Plugin_Handled;
	}
	char targetArg[MAX_TARGET_LENGTH];
	GetCmdArg(1, targetArg, sizeof(targetArg));

	char targetName[MAX_TARGET_LENGTH];
	int targetList[MAXPLAYERS];
	bool tnIsMl;
	int targetCount = ProcessTargetString(targetArg, client, targetList, MAXPLAYERS,
	COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tnIsMl);

	if(targetCount <= 0) 
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < targetCount; i++) 
	{
		int targetClient = targetList[i];
		g_bReplaceObj[targetClient] = !g_bReplaceObj[targetClient];
		
		if(g_bReplaceObj[targetClient])
		{
			SetClientCookie(targetClient, ObjReplacer_cookie, "1");
		}
		else
		{
			SetClientCookie(targetClient, ObjReplacer_cookie, "0");
		}
		

		if(g_bReplaceObj[targetClient])
		{
			if(tnIsMl) 
			{
				CPrintToChatAll("{unique}[O{darkblue}R]{default} Banimento de Placa para %t ativado", targetName);
			} 
			else 
			{
				CPrintToChatAll("{unique}[O{darkblue}R]{default} Banimento de Placa para %s ativado", targetName);
			}
		}
		if(!g_bReplaceObj[targetClient])
		{
			if(tnIsMl) 
			{
				CPrintToChatAll("{unique}[O{darkblue}R]{default} Banimento de Placa para %t desativado", targetName);
			} 
			else 
			{
				CPrintToChatAll("{unique}[O{darkblue}R]{default} Banimento de Placa para %s desativado", targetName);    
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_replacealways(int client, int args)
{
	if(args == 0)
	{
		CReplyToCommand(client, "{unique}[O{darkblue}R]{default}  Este comando requer um alvo válido");
		return Plugin_Handled;
	}
	char targetArg[MAX_TARGET_LENGTH]; // codigo de adicionar players a uma array	
	GetCmdArg(1, targetArg, sizeof(targetArg));

	char targetName[MAX_TARGET_LENGTH];
	int targetList[MAXPLAYERS];
	bool tnIsMl;
	int targetCount = ProcessTargetString(targetArg, client, targetList, MAXPLAYERS,
	COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tnIsMl);

	if(targetCount <= 0) {
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < targetCount; i++) { //função q itera entre os players na lista
	int targetClient = targetList[i];
	g_bReplaceObj[targetClient] = !g_bReplaceObj[targetClient];
	/*if(g_bReplaceObj[targetClient])
	{
		if(tnIsMl) //texto que será exibido no chat
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa ativada para %t", targetName);
		} 
		else 
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa ativada para %s", targetName);    
		}
	}
	if(!g_bReplaceObj)
	{
		if(tnIsMl) //texto que será exibido no chat
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa desativada para %t", targetName);
		} 
		else 
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa desativada para %s", targetName);    
		}
	}*/
	}
	if(tnIsMl) //texto que será exibido no chat
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa alterada para %t", targetName);
		} 
		else 
		{
			CPrintToChatAll("{unique}[O{darkblue}R]{default} Substituição de placa alterada para %s", targetName);    
		}
	return Plugin_Handled;
}

public void Event_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bReplaceObj[client])
    {	
		#if defined DEBUG
		PrintToChatAll("arma deveria ter sido substituida agora");
		#endif
		int weapon = GetPlayerWeaponSlot(client, 2);
		if(IsValidEntity(weapon))	{
			int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(defindex == 474)	{
					int rnd = GetRandomInt(0, 10);
					TF2_RemoveWeaponSlot(client, 2);
					if(rndw[rnd] == 1071)
					{
						TF2Items_GiveWeapon(client, "saxxy", 1071, 69, 8, "150 ; 1 ; 542 ; 0");
					}
					else
					{
						TF2Items_GiveWeapon(client, "saxxy", rndw[rnd], 69, 8, "");
					}
				} 
		}
	}
}
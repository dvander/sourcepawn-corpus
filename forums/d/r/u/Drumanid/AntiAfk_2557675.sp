#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {name = "AntiAfk", author = "Drumanid", version = "2.1", url = "http://vk.com/drumanid"}

Handle g_hTimer[MAXPLAYERS +1];
bool g_bAfk[MAXPLAYERS +1];
int g_iTime[MAXPLAYERS +1], g_iLimit[MAXPLAYERS +1];
int cv_iTime, cv_iLimit, cv_iPunish;
char g_sTranslite[192], cv_sFlagKill[4], cv_sFlagChange[4], cv_sFlagKick[4], cv_sFlagAll[4];

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	ConVar cv;
	(cv = CreateConVar("AA_TIME", "30", "RU: Время перед наказанием | EN: Time of punishment", _, true, 10.0, true, 120.0)).AddChangeHook(Cvar_iTime);
	cv_iTime = cv.IntValue;
	(cv = CreateConVar("AA_LIMIT", "3", "RU: Предупреждения | EN: Warning", _, true, 2.0, true, 6.0)).AddChangeHook(Cvar_iLimit);
	cv_iLimit = cv.IntValue;
	(cv = CreateConVar("AA_PUNISH", "1", "RU: 0 - Кикать / 1 - Перевести в наблюдатели | EN: 0 - Kicked / 1 - Change team 1(spec)", _, true, 0.0, true, 1.0)).AddChangeHook(Cvar_iPunish);
	cv_iPunish = cv.IntValue;
	(cv = CreateConVar("AA_FLAGKILL", "o", "RU: Флаг - иммунитет от убийства | EN: Flag - immunity from murder")).AddChangeHook(Cvar_sFlagKill);
	cv.GetString(cv_sFlagKill, sizeof(cv_sFlagKill));
	(cv = CreateConVar("AA_FLAGCHANGE", "p", "RU: Флаг - иммунитет от изменения команды | EN: Flag - immunity from team change")).AddChangeHook(Cvar_sFlagChange);
	cv.GetString(cv_sFlagChange, sizeof(cv_sFlagChange));
	(cv = CreateConVar("AA_FLAGKICK", "q", "RU: Флаг - иммунитет от кика | EN: Flag - immunity from kick")).AddChangeHook(Cvar_sFlagKick);
	cv.GetString(cv_sFlagKick, sizeof(cv_sFlagKick));
	(cv = CreateConVar("AA_FLAGALL", "z", "RU: Флаг - иммунитет от всего | EN: Flag - immunity from everything")).AddChangeHook(Cvar_sFlagAll);
	cv.GetString(cv_sFlagAll, sizeof(cv_sFlagAll));
	
	LoadTranslations("AntiAfk.phrases");
	AutoExecConfig(true, "AntiAfk");
}

public void Cvar_iTime(ConVar cv, const char[] oldValue, const char[] newValue) { cv_iTime = cv.IntValue; }
public void Cvar_iLimit(ConVar cv, const char[] oldValue, const char[] newValue) { cv_iLimit = cv.IntValue; }
public void Cvar_iPunish(ConVar cv, const char[] oldValue, const char[] newValue) { cv_iPunish = cv.IntValue; }
public void Cvar_sFlagKill(ConVar cv, const char[] oldValue, const char[] newValue) { cv.GetString(cv_sFlagKill, sizeof(cv_sFlagKill)); }
public void Cvar_sFlagChange(ConVar cv, const char[] oldValue, const char[] newValue) { cv.GetString(cv_sFlagChange, sizeof(cv_sFlagChange)); }
public void Cvar_sFlagKick(ConVar cv, const char[] oldValue, const char[] newValue) { cv.GetString(cv_sFlagKick, sizeof(cv_sFlagKick)); }
public void Cvar_sFlagAll(ConVar cv, const char[] oldValue, const char[] newValue) { cv.GetString(cv_sFlagAll, sizeof(cv_sFlagAll)); }

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient) && CheckFlag(iClient, cv_sFlagAll))
	{
		g_iTime[iClient] = cv_iTime;
		g_hTimer[iClient] = CreateTimer(1.0, CheckAfk, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void PlayerSpawn(Event hEvent, const char[] sName, bool bDbc)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	g_bAfk[iClient] = true;
	g_iTime[iClient] = cv_iTime;
}

public Action CheckAfk(Handle hTimer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if(iClient && IsPlayerAlive(iClient) && !IsFakeClient(iClient) && g_bAfk[iClient])
	{
		if(--g_iTime[iClient] > 0)
		{
			if(g_iTime[iClient] > 10.0) return Plugin_Handled;
			else
			{
				SetGlobalTransTarget(iClient);
				FormatEx(g_sTranslite, sizeof(g_sTranslite), "%t", "Warning motion hud", g_iTime[iClient]);
				SetHudTextParams(0.005, 0.5, 1.0, 255, 68, 68, 255, 0, 1.0, 0.1, 0.1);
				ShowHudText(iClient, -1, g_sTranslite);
			}
			
			return Plugin_Continue;
		}
		
		g_iLimit[iClient]++;
		
		FormatEx(g_sTranslite, sizeof(g_sTranslite), "%t", "Warning motion chat", g_iLimit[iClient], cv_iLimit);
		PrintToChat(iClient, g_sTranslite);
		
		if(CheckFlag(iClient, cv_sFlagKill))
		{
			ForcePlayerSuicide(iClient);
		
			FormatEx(g_sTranslite, sizeof(g_sTranslite), "%t", "Kill player", iClient);
			PrintToChatAll(g_sTranslite);
		}
		
		if(g_iLimit[iClient] >= cv_iLimit)
		{
			switch(cv_iPunish)
			{
				case 0:
				{
					if(CheckFlag(iClient,cv_sFlagKick))
					{
						FormatEx(g_sTranslite, sizeof(g_sTranslite), "%t", "Kick message");
						KickClient(iClient, g_sTranslite);
					}
				}
				case 1:
				{
					g_iLimit[iClient] = 0;
					
					if(CheckFlag(iClient, cv_sFlagChange))
					{
						ChangeClientTeam(iClient, 1);
					
						FormatEx(g_sTranslite, sizeof(g_sTranslite), "%t", "Change team");
						PrintToChat(iClient, g_sTranslite);
					}
				}
			}
		}
	}
	
	g_bAfk[iClient] = true;
	g_iTime[iClient] = cv_iTime;
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon)
{
	if(g_bAfk[iClient] && IsPlayerAlive(iClient) && !IsFakeClient(iClient))
	{
		if(iButtons && !(iButtons & IN_LEFT || iButtons & IN_RIGHT))
		{
			g_bAfk[iClient] = false;
			g_iLimit[iClient] = 0;
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if(g_hTimer[iClient] != null)
	{
		delete g_hTimer[iClient];
		g_hTimer[iClient] = null;
	}
	
	g_iLimit[iClient] = 0;
}

bool CheckFlag(int iClient, char[] sFlag)
{
	int iFlagBits = GetUserFlagBits(iClient);
	if(iFlagBits & ReadFlagString("z") || iFlagBits & ReadFlagString(sFlag)) return false;
	return true;
}
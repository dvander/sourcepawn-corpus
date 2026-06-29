#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name	=	"TV Clock",
	author	=	"gOoDnIgHt",
	description	=	"",
	version	=	"1.0",
	url		=	"ExaGame.ir"
};

public void OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SayText2"), UMH, true);
	CreateTimer(5.0, Timer_Clock);
}

public Action UMH(UserMsg MsgId, Handle hBitBuffer, const char[] iPlayers, iNumPlayers, bool bReliable, bool bInit)
{
	char sMessage[1024];

	BfReadByte(hBitBuffer);
	BfReadString(hBitBuffer, sMessage, sizeof(sMessage));
	if (StrEqual(sMessage, "#Cstrike_Name_Change")) return Plugin_Handled;

	return Plugin_Continue;
}

public Action Timer_Clock(Handle timer)
{
	char sName[128], sTime[64];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientSourceTV(i))
		{
			FormatTime(sTime, sizeof(sTime), "SourceTV | %H:%M:%S %p");
			sName = ("%s", sTime);
			SetClientName(i, sName);
		}
	}
}


#include <sourcemod>
#include <sdktools>


public Plugin myinfo = {
	name	=	"TV Clock",
	author	=	"gOoDnIgHt",
	description	=	"",
	version	=	"1.1",
	url		=	"ExaGame.ir"
};
public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("SayText2"), ChangeName, true);
	CreateTimer(1.0, Timer, _, TIMER_REPEAT);
}
public Action ChangeName(UserMsg MsgId, Handle hBitBuffer, const iPlayers[], iNumPlayers, bool bReliable, bool bInit)
{
	char Message[1024];

	BfReadByte(hBitBuffer);
	BfReadByte(hBitBuffer);
	BfReadString(hBitBuffer, Message, sizeof(Message));
	if (StrEqual(Message, "#Cstrike_Name_Change"))
		return Plugin_Handled;

	return Plugin_Continue;
}
public Action Timer(Handle timer)
{
	char Name[128], STime[64];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientSourceTV(i))
		{
			FormatTime(STime, sizeof(STime), "SourceTV | %H:%M:%S %p");
			Name = ("%s", STime);
			SetClientName(i, Name);
		}
	}
}

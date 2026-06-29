#pragma semicolon 1
#include <sourcemod>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Time VIP",
	author = "R1KO & AlmazON",
	version = "1.0.0e"
};

new String:g_sGroup[64];
new g_iStartHours, g_iStartMin;
new g_iEndHours, g_iEndMin;

public OnPluginStart()
{
	decl String:period[12], Handle:hCvar;
	HookConVarChange(hCvar = CreateConVar("sm_vip_time_group", "vip", "Группа VIP-статуса"), OnGroupChange);
	GetConVarString(hCvar, g_sGroup, sizeof(g_sGroup));

	HookConVarChange(hCvar = CreateConVar("sm_vip_time_period", "00:00-05.00", "Начало времени-Конец времени"), OnPeriodChange);
	GetConVarString(hCvar, period, sizeof(period));
	OnPeriodChange(hCvar, "", period);

	AutoExecConfig(true, "time_vip", "vip");
}

public OnGroupChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) strcopy(g_sGroup, sizeof(g_sGroup), sNewValue);
public OnPeriodChange(Handle:hCvar, const String:sOldValue[], String:sNewValue[])
{
	if ((g_iStartHours = strlen(sNewValue)) > 8)
	{
		StringToIntEx(sNewValue[g_iStartHours-2], g_iEndMin);
		sNewValue[g_iStartHours-3] = 0;
		StringToIntEx(sNewValue[IsCharNumeric(sNewValue[g_iStartHours-=5]) ? g_iStartHours--:g_iStartHours+1], g_iEndHours);
		sNewValue[g_iStartHours] = 0;
		StringToIntEx(sNewValue[g_iStartHours-2], g_iStartMin);
		sNewValue[g_iStartHours-3] = 0;
		StringToIntEx(sNewValue, g_iStartHours);
	}
	else LogError("Неверно указан формат времени! Верный: 00:00-05:00");
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client) == false && VIP_IsClientVIP(client) == false)
	{
		decl String:sTime[5], time;
		FormatTime(sTime, sizeof(sTime), "%M%H");
		if ((time = StringToInt(sTime[2])) <= g_iEndHours && time >= g_iStartHours)
		{
			sTime[2] = 0;
			if (time == g_iStartHours)
			{
				if (StringToInt(sTime) < g_iStartMin) return;
			}
			if (time == g_iEndHours)
			{
				if (StringToInt(sTime) > g_iEndMin) return;
			}
			VIP_SetClientVIP(client, 0, AUTH_STEAM, g_sGroup, false);
		}
	}
}

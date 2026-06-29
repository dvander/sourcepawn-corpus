/**
 * vim: set ts=4 :
 * =============================================================================
 * High Ping Kicker
 * Kicks players with a high ping.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

/*
 * Code written by Liam on 3/12/2008.
 *
 * This plugin was written to handle kicking players with a high ping.
 * It will poll them several times over a period of time and if they have
 * a ping higher than your allowed amount, it will kick them.
 *
 * The only cVar is that of the max ping. It can be changed in the ping_kicker.cfg
 * located in <mod>\cfg\sourcemod.
 *
 * This has been tested on both the Orange Box and EP1 versions.
 *
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "2.9"

public Plugin:myinfo =
{
    name = "High Ping Kicker",
    author = "Liam",
    description = "Kicks people with a high ping.",
    version = VERSION,
    url = "http://www.wcugaming.org"
};

/*
 * cVar enable/disable for below options
 */
new Handle:g_Cvar_CheckPing = INVALID_HANDLE;
new Handle:g_Cvar_CheckChoke = INVALID_HANDLE;
new Handle:g_Cvar_CheckLoss = INVALID_HANDLE;
new Handle:g_Cvar_CheckPackets = INVALID_HANDLE;

/*
 * cVar limits for checks
 */
new Handle:g_Cvar_MaxPing = INVALID_HANDLE;
new Handle:g_Cvar_MaxChoke = INVALID_HANDLE;
new Handle:g_Cvar_MaxLoss = INVALID_HANDLE;
new Handle:g_Cvar_MinPacketIn = INVALID_HANDLE;
new Handle:g_Cvar_MinPacketOut = INVALID_HANDLE;
new Handle:g_Cvar_Admins_Immune = INVALID_HANDLE;

new g_MaxPingCheck = 15;
new g_PingCheck[MAXPLAYERS+1];
new g_ChokeCheck[MAXPLAYERS+1];
new g_LossCheck[MAXPLAYERS+1];
new g_PacketInCheck[MAXPLAYERS+1];
new g_PacketOutCheck[MAXPLAYERS+1];
new bool:g_IsHL2DM;

new g_Ping[MAXPLAYERS+1];
new Float:g_Choke[MAXPLAYERS+1];
new Float:g_Loss[MAXPLAYERS+1];
new Float:g_PacketsIn[MAXPLAYERS+1];
new Float:g_PacketsOut[MAXPLAYERS+1];

public OnPluginStart( )
{
	CreateConVars( );
	LoadTranslations("common.phrases");	
	RegAdminCmd("sm_rates", Command_Rates, ADMFLAG_GENERIC, "sm_rates | sm_rates <player>");

	decl String:f_GameDesc[64];
	GetGameDescription(f_GameDesc, sizeof(f_GameDesc), true);

	if(!strcmp(f_GameDesc, "Half-Life 2 Deathmatch"))
		g_IsHL2DM = true;

	AutoExecConfig(true, "hpk");
}

CreateConVars( )
{
	g_Cvar_CheckPing = CreateConVar("sm_checkping", "1", "Check the players ping. 1 = TRUE, 0 = FALSE");
	g_Cvar_CheckChoke = CreateConVar("sm_checkchoke", "1", "Check the players choke. 1 = TRUE, 0 = FALSE");
	g_Cvar_CheckLoss = CreateConVar("sm_checkloss", "1", "Check the players loss. 1 = TRUE, 0 = FALSE");
	g_Cvar_CheckPackets = CreateConVar("sm_checkpackets", "1", "Check the players packets in and out. 1 = TRUE, 0 = FALSE");

	g_Cvar_MaxPing = CreateConVar("sm_maxping", "150", "Max Ping for Players");
	g_Cvar_MaxChoke = CreateConVar("sm_maxchoke", "30.0", "Max Choke for Players");
	g_Cvar_MaxLoss = CreateConVar("sm_maxloss", "30.0", "Max Loss for Players");
	g_Cvar_MinPacketIn = CreateConVar("sm_minpacketin", "30.0", "Min packets in for Players");
	g_Cvar_MinPacketOut = CreateConVar("sm_minpacketout", "50.0", "Min packets out for Players");
	g_Cvar_Admins_Immune = CreateConVar("sm_ping_admins_immune", "1", "1 = True, 0 = False");
	CreateConVar("hpk_version", VERSION, 
        "Current version of High Ping Kicker", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_PingCheck[client] = 0;
	g_ChokeCheck[client] = 0;
	g_LossCheck[client] = 0;
	g_PacketInCheck[client] = 0;
	g_PacketOutCheck[client] = 0;
	return true;
}

public OnMapStart( )
{
	for(new i = 1; i < MAXPLAYERS + 1; i++)
	{
		g_PingCheck[i] = 0;
		g_ChokeCheck[i] = 0;
		g_LossCheck[i] = 0;
		g_PacketInCheck[i] = 0;
		g_PacketOutCheck[i] = 0;
	}
	CreateTimer(15.0, CheckLatency, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd( )
{
	for(new i = 1; i < MAXPLAYERS + 1; i++)
	{
		g_PingCheck[i] = 0;
		g_ChokeCheck[i] = 0;
		g_LossCheck[i] = 0;
		g_PacketInCheck[i] = 0;
		g_PacketOutCheck[i] = 0;
	}
}

public Action:Command_Rates(client, args)
{
    decl String:f_TargetName[MAX_NAME_LENGTH];
    new f_Target;

    if(args > 0)
    {
        GetCmdArg(1, f_TargetName, sizeof(f_TargetName));
        f_Target = FindTarget(client, f_TargetName, true, true);
    }

    if(f_Target == -1)
        return Plugin_Handled;

    if(f_Target == 0)
    {
        new f_MaxClients = GetMaxClients( );

        for(new i = 1; i < f_MaxClients; i++)
        {
            if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
                continue;

            DisplayRateInfo(client, i);
        }
    }
    else
    {
        DisplayRateInfo(client, f_Target);
    }
    return Plugin_Handled;
}

DisplayRateInfo(client, f_Target)
{
    decl String:f_CmdRateString[32], String:f_UpdateRateString[32], 
         String:f_InterpString[32], String:f_RateString[32], String:f_Client[MAX_NAME_LENGTH];

    GetClientName(f_Target, f_Client, sizeof(f_Client));
    GetClientInfo(f_Target, "cl_cmdrate", f_CmdRateString, sizeof(f_CmdRateString));
    GetClientInfo(f_Target, "cl_updaterate", f_UpdateRateString, sizeof(f_UpdateRateString));
    GetClientInfo(f_Target, "rate", f_RateString, sizeof(f_RateString));
    GetClientInfo(f_Target, "cl_interp", f_InterpString, sizeof(f_InterpString));
    new Float:f_Choke = GetClientAvgChoke(f_Target, NetFlow_Outgoing) * 100.0;
    new Float:f_Loss = GetClientAvgLoss(f_Target, NetFlow_Outgoing) * 100.0;
    new f_CmdRate = StringToInt(f_CmdRateString);
    new f_UpdateRate = StringToInt(f_UpdateRateString);
    new Float:f_Interp = StringToFloat(f_InterpString);
    new f_Rate = StringToInt(f_RateString);
    new Float:f_In = GetClientAvgPackets(f_Target, NetFlow_Incoming);
    new Float:f_Out = GetClientAvgPackets(f_Target, NetFlow_Outgoing);
    
    ReplyToCommand(client, "%-32s: Choke: %f, Loss: %f, CmdRate: %d, Update: %d, Interp: %f, Rate: %d, pIn: %f, pOut: %f",
        f_Client, f_Choke, f_Loss, f_CmdRate, f_UpdateRate, f_Interp, f_Rate, f_In, f_Out);
    return;
}

public Action:CheckLatency(Handle:timer)
{
    new MaxClients = GetMaxClients( );
    new team;

    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && IsClientInGame(i)
            && !IsFakeClient(i) && !IsProtectedAdmin(i))
        {
            team = GetClientTeam(i);
            if(team == 3 || team == 2 
                || (g_IsHL2DM && team == 0))
            {
                CheckClientLatency(i);
            }
        }
    }
    return Plugin_Continue;
}

CheckClientLatency(client)
{

	if(GetConVarInt(g_Cvar_CheckPing) == 1)
		CheckClientPing(client);

	if(GetConVarInt(g_Cvar_CheckChoke) == 1)
		CheckClientChoke(client);

	if(GetConVarInt(g_Cvar_CheckLoss) == 1)
		CheckClientLoss(client);

	if(GetConVarInt(g_Cvar_CheckPackets) == 1)
	{
		CheckClientPackets(client);		
	}
    CheckClientForKick(client);	
}

CheckClientPing(client)
{
    new Float:ping = GetClientAvgLatency(client, NetFlow_Outgoing);
    new Float:tickRate = GetTickInterval( );
    decl String:cmdRateString[32];
    GetClientInfo(client, "cl_cmdrate", cmdRateString, sizeof(cmdRateString));
    new cmdRate = StringToInt(cmdRateString);

    if(cmdRate < 20)
        cmdRate = 20;

    ping -= ((0.5/cmdRate) + (tickRate * 1.0));
    ping -= (tickRate * 0.5);
    ping *= 1000.0;

    g_Ping[client] = RoundToZero(ping);

    if(g_Ping[client] > GetConVarInt(g_Cvar_MaxPing))
        g_PingCheck[client]++;
    else
    {
        if(g_PingCheck[client] > 0)
            g_PingCheck[client]--;
    }
}

CheckClientChoke(client)
{
	g_Choke[client] = GetClientAvgChoke(client, NetFlow_Outgoing) * 100.0;

	if(g_Choke[client] > GetConVarFloat(g_Cvar_MaxChoke))
		g_ChokeCheck[client]++;
	else
	{
		if(g_ChokeCheck[client] > 0)
			g_ChokeCheck[client]--;
	}

}

CheckClientLoss(client)
{
	g_Loss[client] = GetClientAvgLoss(client, NetFlow_Outgoing) * 100.0;

	if(g_Loss[client] > GetConVarFloat(g_Cvar_MaxLoss))
		g_LossCheck[client]++;
	else
	{
		if(g_LossCheck[client] > 0)
			g_LossCheck[client]--;
	}
}

CheckClientPackets(client)
{
	g_PacketsIn[client] = GetClientAvgPackets(client, NetFlow_Incoming);
	g_PacketsOut[client] = GetClientAvgPackets(client, NetFlow_Outgoing);

	if(g_PacketsIn[client] < GetConVarFloat(g_Cvar_MinPacketIn))
		g_PacketInCheck[client]++;
	else
	{
		if(g_PacketInCheck[client] > 0)
			g_PacketInCheck[client]--;
	}

	if(g_PacketsOut[client] < GetConVarFloat(g_Cvar_MinPacketOut))
		g_PacketOutCheck[client]++;
	else
	{
		if(g_PacketOutCheck[client] > 0)
			g_PacketOutCheck[client]--;
	}
}

CheckClientForKick(client)
{
	if(g_PingCheck[client] >= g_MaxPingCheck)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        KickClient(client, "Your ping (%d) is too high. Max ping: %d", g_Ping[client], GetConVarInt(g_Cvar_MaxPing));
        PrintToChatAll("%s was kicked for high ping. (%d)", name, g_Ping[client]);
    }

	if(g_ChokeCheck[client] >= g_MaxPingCheck)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        KickClient(client, "Your choke (%f) is too high. Max choke: %f", g_Choke[client], GetConVarInt(g_Cvar_MaxChoke));
        PrintToChatAll("%s was kicked for high ping. (%f)", name, g_Choke[client]);
    }

	if(g_LossCheck[client] >= g_MaxPingCheck)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        KickClient(client, "Your loss (%f) is too high. Max loss: %f", g_Loss[client], GetConVarInt(g_Cvar_MaxLoss));
        PrintToChatAll("%s was kicked for high loss. (%f)", name, g_Loss[client]);
    }

	if(g_PacketInCheck[client] >= g_MaxPingCheck)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        KickClient(client, "Your incoming packets (%f) are too low. Min. Packets in: %f", 
			g_PacketsIn[client], GetConVarFloat(g_Cvar_MinPacketIn));
        PrintToChatAll("%s was kicked for low minimum packets. (%f)", name, g_PacketsIn[client]);
    }

	if(g_PacketOutCheck[client] >= g_MaxPingCheck)
    {
        decl String:name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        KickClient(client, "Your outgoing packets (%f) are too low. Min. Packets out: %f", 
			g_PacketsOut[client], GetConVarFloat(g_Cvar_MinPacketOut));
        PrintToChatAll("%s was kicked for low outgoing packets. (%f)", name, g_PacketsOut[client]);
    }
}

bool:IsProtectedAdmin(client)
{
    if(GetConVarInt(g_Cvar_Admins_Immune) == 0)
        return false;

    new AdminId:admin = GetUserAdmin(client);

    if(admin == INVALID_ADMIN_ID)
        return false;

    return true;
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAXHUDS 5

int g_iHudLayout[MAXHUDS], g_iCounter[MAXHUDS][2];
bool g_bLoaded, g_bAllow[MAXPLAYERS + 1];
ConVar cFakeClient, cState;

static const char vtable[][] = 
{
	"HUD_SCORE_1",
	"HUD_SCORE_2",
	"HUD_SCORE_3",
	"HUD_SCORE_4",
	"HUD_LEFT_TOP",
	"HUD_LEFT_BOT",
	"HUD_TICKER",
	"HUD_MID_BOX",
	"HUD_FAR_LEFT",
	"HUD_FAR_RIGHT",
	"HUD_SCORE_TITLE",
	"HUD_RIGHT_TOP",
	"HUD_RIGHT_BOT",
	"HUD_MID_TOP",
	"HUD_MID_BOT"
};

public Plugin myinfo =
{
    name        = "[L4D2] Hud Counter",
    author      = "BHaType",
    description = "Count how many player killed",
    version     = "0.2",
    url         = "N/A"
}

public void OnPluginStart()
{
	cFakeClient = CreateConVar("hud_counter_enable_fake_client",  "0", "Enable counter for bots 0 - Disable 1 - Enable", FCVAR_NONE);
	cState = CreateConVar("hud_counter_pos",  "0", "States of pos 0 - Original, 1 - Lower, 2 - Lower++, 3 - Top", FCVAR_NONE);

	HookEvent("player_death", eEvent);
	HookEvent("round_start", eEvent);
	
	AutoExecConfig(true, "hud_counter");
}

public void OnMapStart()
{
	g_bLoaded = true;
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void OnConfigsExecuted()
{
	int entity = CreateEntityByName("logic_script");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "vscripts", "VSLib");
		DispatchSpawn(entity);
		SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::1:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	if(!g_bLoaded)
		return;
		
	if(strcmp(name, "round_start") == 0)
	{
		for(int i = 1; i < MAXHUDS; i++)
		{
			if(IsClientInGame(i))
			{
				g_bAllow[i] = false;
				g_iCounter[i][0] = 0;
				g_iCounter[i][1] = 0;
			}
		}
		
		int entity = CreateEntityByName("logic_script");
		if( entity != -1 )
		{
			DispatchKeyValue(entity, "vscripts", "VSLib");
			DispatchSpawn(entity);
			SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:Kill::1:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if(client && GetClientTeam(client) == 2)
	{
		if(victim)
			g_iCounter[client][1]++;
		else
			g_iCounter[client][0]++;
	}
	else
		return;
	
	if(client && !g_bAllow[client])
	{
		int index;
		char szBuffer[PLATFORM_MAX_PATH];
		
		for(int i; i <= MaxClients; i++)
		{
			if(g_iHudLayout[i] == 0)
			{
				index = i;
				g_iHudLayout[index] = GetClientUserId(client);
				CreateTimer(0.3, tCheck, index, TIMER_REPEAT);
				g_bAllow[client] = true;
				break;
			}
		}
		
		Format(szBuffer, sizeof szBuffer, "scripts/vscripts/loadout_index_%i.nut", index);
		
		File hCfg = OpenFile(szBuffer, "w");
		
		hCfg.WriteLine("::layout <- HUD.Item(\"%N Infected: {num} Bosses: {doublea}\");", client);
		hCfg.WriteLine("layout.SetValue(\"num\", %i);", g_iCounter[client][0]);
		hCfg.WriteLine("layout.SetValue(\"doublea\", %i);", g_iCounter[client][1]);
		hCfg.WriteLine("layout.AttachTo(%s);", vtable[index + cState.IntValue]);
		hCfg.WriteLine("layout.SetPositionX(0);");
		hCfg.WriteLine("layout.SetPositionY(%i);", 1 + index);
		hCfg.WriteLine("layout.Resize(0.6, 0.035);");
		hCfg.WriteLine("layout.SetWidth(0.25);");
		hCfg.WriteLine("layout.SetFlags(HUD_FLAG_NOBG);");
	
		delete hCfg;
		
		Format(szBuffer, sizeof szBuffer, "loadout_index_%i", index);

		int entity = CreateEntityByName("logic_script");
		if( entity != -1 )
		{
			DispatchKeyValue(entity, "vscripts", szBuffer);
			DispatchSpawn(entity);
			SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:Kill::1:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
}

public Action tCheck (Handle timer, int index)
{
	if(GetClientOfUserId(g_iHudLayout[index]) == 0 || (cFakeClient.IntValue == 0 && IsFakeClient(GetClientOfUserId(g_iHudLayout[index]))))
	{
		char szBuffer[PLATFORM_MAX_PATH];
		Format(szBuffer, sizeof szBuffer, "scripts/vscripts/loadout_index_%i.nut", index);
		
		File hCfg = OpenFile(szBuffer, "w");
		hCfg.WriteLine("::layout <- HUD.Item(\"\");");
		hCfg.WriteLine("layout.AttachTo(%s);", vtable[index]);
		hCfg.WriteLine("");
		hCfg.WriteLine("layout.Detach();");
		delete hCfg;
		
		Format(szBuffer, sizeof szBuffer, "loadout_index_%i", index);
		int entity = CreateEntityByName("logic_script");
		if( entity != -1 )
		{
			DispatchKeyValue(entity, "vscripts", szBuffer);
			DispatchSpawn(entity);
			SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:Kill::1:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}

		g_iHudLayout[index] = 0;
		
		g_bAllow[GetClientOfUserId(g_iHudLayout[index])] = false;
		return Plugin_Stop;
	}

	UpdateData(index);
	return Plugin_Continue;
}

void UpdateData(int index)
{
	int client = GetClientOfUserId(g_iHudLayout[index]);
	
	char szBuffer[PLATFORM_MAX_PATH];
	Format(szBuffer, sizeof szBuffer, "scripts/vscripts/loadout_index_%i.nut", index);
	
	
	File hCfg = OpenFile(szBuffer, "w");
	
	hCfg.WriteLine("::layout <- HUD.Item(\"%N Infected: {num} Bosses: {doublea}\");", client);
	hCfg.WriteLine("layout.SetValue(\"num\", %i);", g_iCounter[client][0]);
	hCfg.WriteLine("layout.SetValue(\"doublea\", %i);", g_iCounter[client][1]);
	hCfg.WriteLine("layout.AttachTo(%s);", vtable[index + cState.IntValue]);
	hCfg.WriteLine("layout.SetPositionX(0);");
	hCfg.WriteLine("layout.SetPositionY(3);");
	hCfg.WriteLine("layout.Resize(0.6, 0.035);");
	hCfg.WriteLine("layout.SetWidth(0.25);");
	hCfg.WriteLine("layout.SetFlags(HUD_FLAG_NOBG);");
	
	delete hCfg;
	
	Format(szBuffer, sizeof szBuffer, "loadout_index_%i", index);
	
	int entity = CreateEntityByName("logic_script");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "vscripts", szBuffer);
		DispatchSpawn(entity);
		SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::1:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}
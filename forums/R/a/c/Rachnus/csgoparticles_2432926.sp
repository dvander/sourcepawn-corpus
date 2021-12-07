#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

KeyValues g_kvParticles;
int g_iParticleSystem[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
char g_cClientSection[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
bool g_bParentToggle[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "CS:GO Particles",
	author = PLUGIN_AUTHOR,
	description = "Display CS:GO particles",
	version = PLUGIN_VERSION,
	url = "http://rachnus.blogspot.fi/"
	
};

public void OnPluginStart()
{	
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_iParticleSystem[i] = INVALID_ENT_REFERENCE;
		g_bParentToggle[i] = false;
	}
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/csgoparticles_configs.txt");
	g_kvParticles = new KeyValues("particles");
	
	if(!g_kvParticles.ImportFromFile(path))
		SetFailState("Could not open %s", path);
	
	RegAdminCmd("sm_particlemenu", Command_ParticleMenu, ADMFLAG_GENERIC, "Displays a menu of all CS:GO particles");
	RegAdminCmd("sm_pm", Command_ParticleMenu, ADMFLAG_GENERIC, "Displays a menu of all CS:GO particles");
	RegAdminCmd("sm_delparticle", Command_DelParticle, ADMFLAG_GENERIC, "Deletes clients particle system");
	RegAdminCmd("sm_toggleparent", Command_ToggleParent, ADMFLAG_GENERIC, "If toggled, particle effect will follow player, if not it will be created infront of players head");
}

bool CreateParticle(int client, char []particle)
{
	int ent = EntRefToEntIndex(g_iParticleSystem[client]);
		
	if(ent && ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
		
	}
	
	ent = CreateEntityByName("info_particle_system");
	
	float particleOrigin[3];
	
	if(g_bParentToggle[client])
		GetClientAbsOrigin(client, particleOrigin);
	else
		GetClientEyePosition(client, particleOrigin);

	DispatchKeyValue(ent , "start_active", "0");
	DispatchKeyValue(ent, "effect_name", particle);
	DispatchSpawn(ent);
	
	TeleportEntity(ent , particleOrigin, NULL_VECTOR,NULL_VECTOR);
	
	
	if(g_bParentToggle[client])
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", client, ent, 0);
	}
	
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");
	
	g_iParticleSystem[client] = EntIndexToEntRef(ent);
	PrintToChat(client, " \x04[CS:GO Particles] \x01Particle system created (\x03'%s'\x01)!", particle);

	return true;
}

public Action Command_ToggleParent(int client, int args)
{
	if(g_bParentToggle[client])
	{
		g_bParentToggle[client] = false;
		PrintToChat(client, " \x04[CS:GO Particles] \x01Particle effects are no longer parented!");
	}
	else
	{
		g_bParentToggle[client] = true;
		PrintToChat(client, " \x04[CS:GO Particles] \x01Particle effects are now parented!");
	}
	return Plugin_Handled;
}

public Action Command_DelParticle(int client, int args)
{
	if(args < 1)
	{
		int ent = EntRefToEntIndex(g_iParticleSystem[client]);
		
		if(ent && ent != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(ent, "Stop");
			AcceptEntityInput(ent, "Kill");
			
			PrintToChat(client, " \x04[CS:GO Particles] \x01Particle system deleted!");
		}
		else
			PrintToChat(client, " \x04[CS:GO Particles] \x01You have not spawned a particle!");
		
		g_iParticleSystem[client] = INVALID_ENT_REFERENCE;
	}
	else
		ReplyToCommand(client, " \x04[CS:GO Particles] \x01Usage: sm_delparticle");
		
	return Plugin_Handled;
}

public int PCFMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char info[PLATFORM_MAX_PATH];
	GetMenuItem(menu, param2, info, sizeof(info));
	
	if(action == MenuAction_Select)
	{
		g_kvParticles.Rewind();
		
		if(g_kvParticles.JumpToKey(info))
		{
			if(g_kvParticles.GotoFirstSubKey())
			{
				char particleName[PLATFORM_MAX_PATH];
				Format(g_cClientSection[param1], PLATFORM_MAX_PATH, "%s", info);
				Menu menuParticles = new Menu(ParticlesMenuHandler);
				char menuTitle[PLATFORM_MAX_PATH];
				Format(menuTitle, sizeof(menuTitle), "%s particles", g_cClientSection[param1]);
				menuParticles.SetTitle(menuTitle);
				
				do 
				{
					g_kvParticles.GetString("name", particleName, sizeof(particleName));
					menuParticles.AddItem(particleName, particleName);
	
				} while (g_kvParticles.GotoNextKey());
				
				menuParticles.ExitBackButton = true;
				menuParticles.ExitButton = true;
				menuParticles.Display(param1, MENU_TIME_FOREVER);
			}
		}
		g_kvParticles.Rewind();	
	}
	
	if(action == MenuAction_End)
	{
		if(menu != INVALID_HANDLE)
			delete menu;
	}
}

public int ParticlesMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char info[PLATFORM_MAX_PATH];
	GetMenuItem(menu, param2, info, sizeof(info));
	if(action == MenuAction_Select)
	{
		CreateParticle(param1, info);
		
		g_kvParticles.Rewind();
		
		if(g_kvParticles.JumpToKey(g_cClientSection[param1]))
		{
			if(g_kvParticles.GotoFirstSubKey())
			{
				
				char particleName[PLATFORM_MAX_PATH];
				
				Menu menuParticles = new Menu(ParticlesMenuHandler);
				char menuTitle[PLATFORM_MAX_PATH];
				
				Format(menuTitle, sizeof(menuTitle), "%s particles", g_cClientSection[param1]);
				
				menuParticles.SetTitle(menuTitle);
				do 
				{
					g_kvParticles.GetString("name", particleName, sizeof(particleName));
					menuParticles.AddItem(particleName, particleName);

				} while (g_kvParticles.GotoNextKey());
				
				menuParticles.ExitBackButton = true;
				menuParticles.ExitButton = true;
				menuParticles.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		g_kvParticles.Rewind();	
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		Command_ParticleMenu(param1, 0);
	}
	
	if(action == MenuAction_End)
	{
		if(menu != INVALID_HANDLE)
			delete menu;
	}
}

public Action Command_ParticleMenu(int client, int args)
{
	char sectionName[PLATFORM_MAX_PATH];
	
	Menu menu = new Menu(PCFMenuHandler);
	menu.SetTitle("Particle files (.pcf)");
	
	g_kvParticles.Rewind();
	
	if(g_kvParticles.GotoFirstSubKey())
	{
		do 
		{
			g_kvParticles.GetSectionName(sectionName, sizeof(sectionName));
			menu.AddItem(sectionName, sectionName);

		} while (g_kvParticles.GotoNextKey());
	}
	else
		ReplyToCommand(client, " \x04[CS:GO Particles] \x01No keyvalues not found!");
		
	g_kvParticles.Rewind();
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	if(IsValidEntity(g_iParticleSystem[client]))
		AcceptEntityInput(g_iParticleSystem[client], "Kill");
	
	g_bParentToggle[client] = false;
	g_cClientSection[client] = "";
	g_iParticleSystem[client] = INVALID_ENT_REFERENCE;
}
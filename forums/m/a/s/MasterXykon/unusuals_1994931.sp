#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <menus>

#pragma semicolon 1

#define NO_ATTACH 0
#define ATTACH_HEAD 2

#define EFFECTSFILE				"unusuals.cfg"

new particle;
new String:effectArg[64];
new String:EffectsList[PLATFORM_MAX_PATH];

#define PLUGIN_VERSION      "1.00"

public Plugin:myinfo =
{
    name        = "Custom Unusuals",
    author      = "Master Xykon",
    description = "Apply Custom Unusual Effects",
    version     = PLUGIN_VERSION
};

public OnPluginStart()
{
    CreateConVar("sm_unusual_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
    BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);

    RegConsoleCmd("sm_unusual_spawn", UnusualHead, "Become Unusual");
    RegConsoleCmd("sm_unusual", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_customunusuals", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_unusuals", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_u", UnusualMenu, "Unusual Menu");
    RegConsoleCmd("sm_unusual_delete", DeleteParticle, "Remove Unusual");
    RegConsoleCmd("sm_ud", DeleteParticle, "Remove Unusual");
}

public OnClientDisconnect(client)
{
    DeleteParticle(client, particle);
}

public Action:UnusualHead(client, args)
{
    if(args == 1)
    {
        GetCmdArgString(effectArg, sizeof(effectArg));

        CreateParticle(effectArg, 300.0, client, ATTACH_HEAD);
        PrintToChat(client, "[Custom Unusuals] You've been Unusual'd!");
		
        return Plugin_Handled;
    }

    PrintToConsole(client, "[Custom Unusuals] Usage: sm_unusual_spawn <effect_name>");
	
    return Plugin_Handled;
}

public Action:UnusualOff(client)
{
    DeleteParticle(client, particle);
    PrintToChat(client, "[Custom Unusuals] Your effect wore off!");

    return Plugin_Handled;
}

stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
    particle = CreateEntityByName("info_particle_system");
    
    if (IsValidEdict(particle))
    {
        decl Float:pos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        pos[0] += xOffs;
        pos[1] += yOffs;
        pos[2] += zOffs;
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", type);

        if (attach != NO_ATTACH)
        {
            SetVariantString("!activator");
            AcceptEntityInput(particle, "SetParent", entity, particle, 0);
        
            if (attach == ATTACH_HEAD)
            {
                SetVariantString("head");
                AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
            }
        }
        DispatchKeyValue(particle, "targetname", "present");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");
    }
    else
    {
        LogError("(CreateParticle): Could not create info_particle_system");
    }
    
    return INVALID_HANDLE;
}

public Action:DeleteParticle(client, any)
{
    if (IsValidEdict(particle))
    {
        new String:classname[64];

        GetEdictClassname(particle, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(particle, "Stop");
			AcceptEntityInput(particle, "Kill");
		}
    }
}

public MenuHandler1(Handle:menu, MenuAction:action, iClient, param1)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param1, info, sizeof(info));
		PrintToConsole(iClient, "[Custom Unusuals] You selected effect: %d", info);
		FakeClientCommandEx(iClient, "sm_unusual_spawn %s", info);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client's Unusual menu was cancelled.  Reason: %d", param1);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*
public Action:UnusualMenu(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuTitle(menu, "Unusual Effects");
	AddMenuItem(menu, "none", "CANCEL");
	AddMenuItem(menu, "gabe", "Gabe");
	AddMenuItem(menu, "fluttershy", "Fluttershy");
	AddMenuItem(menu, "derpy", "Derpy");
	AddMenuItem(menu, "rd", "Rainbow Dash");
	AddMenuItem(menu, "unusual_cake", "Cake");
	AddMenuItem(menu, "unusual_energyball", "Energy Ball");
	AddMenuItem(menu, "unusual_fireball", "Fire Ball");
	AddMenuItem(menu, "unusual_health", "Health");
	AddMenuItem(menu, "unusual_jarate", "Jarate");
	AddMenuItem(menu, "unusual_knife", "Knife");
	AddMenuItem(menu, "superrare_circling_skull", "[Valve Unused] Circling Skull");
	AddMenuItem(menu, "unusual_storm_blood", "[Valve Unused] Blood Rain");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}
*/

public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	DeleteParticle(iClient, particle);
}

public Action:UnusualMenu(client, args)
{
	new String:EffectID[128];
	new String:EffectName[128];
	new String:Line[255];
	new Len = 0, NameLen = 0, IDLen = 0;
	new i,j,data,count = 0;

	new Handle:h_UnusualMenu = CreateMenu(MenuHandler1);
	SetMenuTitle(h_UnusualMenu, "Custom Unusual effect :");
	
	new Handle:file = OpenFile(EffectsList, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("[Custom Unusuals] Could not open file %s", EFFECTSFILE);
		CloseHandle(file);
		return Plugin_Handled;
	}

	while (!IsEndOfFile(file))
	{
		count++;
		ReadFileLine(file, Line, sizeof(Line));
		Len = strlen(Line);
		data = 0;
		TrimString(Line);
		if(Line[0] == '"')
		{
			for (i=0; i<Len; i++)
			{
				if (Line[i] == '"')
				{
					i++;
					data++;
					j = i;
					while(Line[j] != '"' && j < Len)
					{
						if(data == 1)
						{
							EffectName[j-i] = Line[j];
							NameLen = j-i;
						}
						else
						{
							EffectID[j-i] = Line[j];
							IDLen = j-i;
						}
						j++;
					}
					i = j;
				}	
			} 
		}
		if(data != 0 && j <= Len)
			AddMenuItem(h_UnusualMenu, EffectID, EffectName);
		else if(Line[0] != '*' && Line[0] != '/')
			LogError("[Custom Unusuals] %s can't read line : %i ",EFFECTSFILE, count);
			
		for(i = 0; i <= NameLen; i++)
			EffectName[i] = '\0';
		for(i = 0; i <= IDLen; i++)
			EffectID[i] = '\0';
	}
	CloseHandle(file);

	SetMenuExitButton(h_UnusualMenu, true);
	DisplayMenu(h_UnusualMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
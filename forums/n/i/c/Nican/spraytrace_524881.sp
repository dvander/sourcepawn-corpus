#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "3.1"


//I am doing all this global for those "happy" people who spray something and quit the server
new Float:SprayTrace[MAXPLAYERS + 1][3];
new String:SprayName[MAXPLAYERS + 1][64];
new String:SprayID[MAXPLAYERS + 1][32];
new SpraytTime[MAXPLAYERS + 1];

#define MAXDIS 0
#define REFRESHRATE 1

new Handle:g_cvars[2];
new maxplayers;
new Handle:spraytimer = INVALID_HANDLE;
new Handle:hTopMenu;

new Handle:HudMessage;
new bool:CanHud;

public Plugin:myinfo = 
{
	name = "Spray tracer",
	author = "Nican132",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_spray_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
 	
	RegConsoleCmd("sm_tracespray", TestTrace);
	
	g_cvars[REFRESHRATE] = CreateConVar("sm_spray_refresh","1.0","How often the program will trace to see player's spray");
	g_cvars[MAXDIS] = CreateConVar("sm_spray_dista","50.0","How far away the spray will be traced to");
	
	HookConVarChange(g_cvars[REFRESHRATE], ConVarChange);
	
	AddTempEntHook("Player Decal",PlayerSpray);
	
	Createtimers();
	
	new String:gamename[31];
	GetGameFolderName(gamename, sizeof(gamename));
	
	CanHud = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false);
	if(CanHud){
        HudMessage = CreateHudSynchronizer();
    }
		
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
    Createtimers();
}

stock Createtimers(){
    if(spraytimer != INVALID_HANDLE){
        KillTimer( spraytimer );
        spraytimer = INVALID_HANDLE;
    }
    
    new Float:timer = GetConVarFloat( g_cvars[REFRESHRATE] );
    
    if( timer > 0.0){
        //LogMessage("Creating timer!")
        spraytimer = CreateTimer( timer, CheckAllTraces, 0, TIMER_REPEAT);    
    }
}


public Action:CheckAllTraces(Handle:timer, any:useless){
    new i, a;
    new Float:MaxDis = GetConVarFloat(g_cvars[MAXDIS]);	 
    new Float:pos[3];
    new bool:HasChangedHud = false;
    
    //God pray for the processor
    for(i = 1; i<= maxplayers; i++){
        if(!IsClientInGame(i))
            continue;
                
        if(IsFakeClient(i))
            continue;
            
        if(GetPlayerEye(i, pos)){
            for(a=1; a<=maxplayers;a++){
                if(GetVectorDistance(pos, SprayTrace[a]) <= MaxDis){
                    if(CanHud){
                        //Save bandwidth, only send the message if needed.
                        if(!HasChangedHud){
                            HasChangedHud = true;
                            SetHudTextParams(0.04, 0.6, 1.0, 255, 50, 50, 255);
                        }
                        
                        ShowSyncHudText(i, HudMessage, "Spray sprayed by: %s", SprayName[a]);
                    } else {
                        PrintHintText(i, "Spray sprayed by: %s", SprayName[a]);
                    }
                    break;
                }
            }
        }
    }
}

public OnMapStart(){
	maxplayers = GetMaxClients();
	new i;
	
	for(i = 1; i<= maxplayers; i++){
        SprayTrace[ i ][0] = 0.0
        SprayTrace[ i ][1] = 0.0
    }
}


public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay){
	new client=TE_ReadNum("m_nPlayer");
	TE_ReadVector("m_vecOrigin",SprayTrace[client]);
    
	SpraytTime[client] = RoundFloat(GetGameTime());
	GetClientName(client, SprayName[client], 64);
	GetClientAuthString(client, SprayID[client], 32);
}

public Action:TestTrace(client, args){    
    new Float:pos[3];
    if(GetPlayerEye(client, pos)){
		new Float:MaxDis = GetConVarFloat(g_cvars[MAXDIS]);	 
	 	for(new i = 1; i<= maxplayers; i++){
	 	 
			if(GetVectorDistance(pos, SprayTrace[i]) <= MaxDis){
				new time = RoundFloat(GetGameTime()) - SpraytTime[i];
			 	//PrintToChat(client, "Spray found: %d", i);
				PrintToChat(client, "Spray by: %s (%s), %d seconds ago", SprayName[i], SprayID[i], time);
				return Plugin_Handled;
			}
		}
    }
	
    PrintToChat(client, "No spray were found on where you are looking at");

    return Plugin_Handled;
}

stock bool:GetPlayerEye(client, Float:pos[3]){
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace)){
	 	//This is the first function i ever sow that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask){
 	return entity > maxplayers;
}




/* MENU */
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
	
	AddToTopMenu(hTopMenu,
			"sm_tracespray",
			TopMenuObject_Item,
			AdminMenu_TraceSpray,
			player_commands,
			"sm_tracespray",
			ADMFLAG_SLAY);
}


public AdminMenu_TraceSpray(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spray trace");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		TestTrace(param, 0);
	}
}

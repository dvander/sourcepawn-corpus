#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "3.0BETA"


//I am doing all this global for those "happy" people who spray something and quit the server
new Float:SprayTrace[MAXPLAYERS + 1][3];
new String:SprayName[MAXPLAYERS + 1][64];
new String:SprayID[MAXPLAYERS + 1][32];
new SpraytTime[MAXPLAYERS + 1];

new SeeTracesHud[ MAXPLAYERS + 1];

#define MAXDIS 0
#define REFRESHRATE 1
#define HUDSETTING 2

new Handle:g_cvars[3];
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
	g_cvars[HUDSETTING] = CreateConVar("sm_spray_hud","1","0=disabled 1=enabled 2=not allowed");
	
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

public OnClientDisconnect(client){
    SeeTracesHud[ client ] = false;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen){
    SeeTracesHud[ client ] = GetConVarInt(g_cvars[HUDSETTING]);
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
    if( GetConVarInt(g_cvars[HUDSETTING]) == 2 ) return;

    new i, a;
    new Float:MaxDis = GetConVarFloat(g_cvars[MAXDIS]);	 
    new Float:pos[3];
    new bool:HasChangedHud = false;
    
    //God pray for the processor
    for(i = 1; i<= maxplayers; i++){
        if(!IsClientInGame(i) || IsFakeClient(i) || SeeTracesHud[i] != 1)
            continue;
            
        if(GetPlayerEye(i, pos)){
            for(a=1; a<=maxplayers;a++){
                if( IsClientInGame(a) && GetVectorDistance(pos, SprayTrace[a]) <= MaxDis){
                
                    if(CanHud){
                        //Save bandwidth, only send the message if needed.
                        if(!HasChangedHud){
                            HasChangedHud = true;
                            SetHudTextParams(0.04, 0.6, 1.0, 255, 50, 50, 255);
                        }
                        
                        ShowSyncHudText(i, HudMessage, "Spray sprayed by: %s", SprayName[i]);
                    } else {
                        PrintHintText(i, "\x04[SPRAY]\x01 Spray sprayed by: %s", SprayName[i]);
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
        SeeTracesHud[ i ] = false;
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
				PrintToChat(client, "\x04[SPRAY]\x01 Spray by: %s (%s), %d seconds ago", SprayName[i], SprayID[i], time);
				
				DisplaySprayMenu(client, i);
				
				return Plugin_Handled;
			}
		}
    }
	
   //PrintToChat(client, "No spray were found on where you are looking at");
    DisplaySprayMenu(client, 0);

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


DisplaySprayMenu(client, target)
{
    new Handle:menu = CreateMenu(MenuHandler_Spray);
    decl String:title[100];
	
    if(SeeTracesHud[client] == 1){
        AddMenuItem(menu, "onoff", "Turn tracer OFF\n");
    } else {
        AddMenuItem(menu, "onoff", "Turn tracer ON\n");
    }
	
	
    if (target != 0){
        SetMenuTitle(menu, "Spray action: %s", SprayName[target]);
	
        new AdminId:id = GetUserAdmin(client);
        if( id != INVALID_ADMIN_ID ){
            new adminflags = GetAdminFlags(id, Access_Real);
            new isroot = adminflags & ADMFLAG_ROOT;
            
            target = GetClientUserId( target );
        	
        	
            Format(title, sizeof(title), "1%d", target);
            AddMenuItem(menu, title, "Warn Player");
        	
        	
            if( adminflags & ADMFLAG_SLAY  || isroot ){
                Format(title, sizeof(title), "2%d", target);
            	AddMenuItem(menu, title, "Slay Player");
        	}
        	
            if( adminflags & ADMFLAG_KICK  || isroot ){
                Format(title, sizeof(title), "3%d", target);
            	AddMenuItem(menu, title, "Kick Player");
        	}
        	
            if( adminflags & ADMFLAG_BAN || isroot ){
                Format(title, sizeof(title), "4%s", target);
            	AddMenuItem(menu, title, "Ban Player");
        	}
        	
        }
    } else {
        Format(title, sizeof(title), "Spray action");
        SetMenuTitle(menu, title);
    }
	
    DisplayMenu(menu, client, 20);
}



public MenuHandler_Spray(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
	   
	   
	   
        if(StrEqual(info, "onoff") ){
            if(GetConVarInt(g_cvars[HUDSETTING]) == 2){
                PrintToChat(client, "\x04[SPRAY]\x01 You can not use HUD on this server!");
                return;
            }
        
            SeeTracesHud[ client ] = !SeeTracesHud[ client ];
            return;
        } else if(info[0] == '1'){
            new target = StringToInt(info[1]);
            
            if(IsClientConnected(target)){
                PrintToChat(target, "\x04[SPRAY]\x01 Admin does not like your spray, stop using it!");
                return;
            }
        } else if(info[0] == '2'){
            ActionOnClient(client, StringToInt(info[1]), Admin_Slay);
        } else if(info[0] == '3'){
            ActionOnClient(client, StringToInt(info[1]), Admin_Kick);
        } else if(info[0] == '4'){
            ActionOnClient(client, StringToInt(info[1]), Admin_Ban);
        }
	}
}

stock ActionOnClient(client, target, AdminFlag:flag){
    target = GetClientOfUserId( target );
    if( target == 0 ){
        PrintToChat(target, "\x04[SPRAY]\x01 Target is no longer connected");
    }


    new AdminId:clientadmin =  GetUserAdmin(client);    
    
    if (!IsClientConnected(target)){
        PrintToChat(client, "\x04[SPRAY]\x01  Player no longer available.");
        return;
	}
    else if (!CanUserTarget(client, target)){
        PrintToChat(client, "\x04[SPRAY]\x01  Unable to target.");
        return;
    }
    
    if(!GetAdminFlag(clientadmin, flag) ){
        PrintToChat(client, "\x04[SPRAY]\x01  You do not have enough acess.");
        return;
    }
    
    PrintToChatAll("\x04[SPRAY]\x01  %N just got punished for bad spray!", target );
    
    switch(flag){
        case Admin_Kick: {  KickClient( target, "Bad Spray" );                                         }
        case Admin_Slay: {  ForcePlayerSuicide( target );                                              }
        case Admin_Ban:  {  BanClient(target, 60, BANFLAG_AUTO, "Ban Spray", "Bad Spray", "", client); }
    }
}

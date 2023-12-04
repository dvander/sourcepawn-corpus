#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <zombiereloaded>

#define FFADE_IN  	0x0001
#pragma semicolon 1

new bool:bUserHasBoost[ 33 ];

new g_Time = 10;
new bool:g_RoundEnd = false;

new gPlayerMoney;

new hasNinja[MAXPLAYERS+1];
new bool:onninja[MAXPLAYERS+1];
new bool:canuse[MAXPLAYERS+1];

new g_BlueGlowSprite;
new g_RedGlowSprite;
new g_GreenGlowSprite;
new g_YellowGlowSprite;
new g_PurpleGlowSprite;
new g_OrangeGlowSprite;
new g_WhiteGlowSprite;
new precache_fire_line;

new modelindex;
new haloindex;


new g_SmokeSprite;
new g_LightningSprite;


public Plugin:myinfo = 
{
	name = "Boost",
	description = "Speed Mario star efect",
	author = "AMAURI BUENO DOS SANTOS",
	version = SOURCEMOD_VERSION,
	url = "https://github.com/007amauri/zombiereload5"
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	RegAdminCmd("admin_he", Command_Boost, ADMFLAG_KICK, "Kicks a player by name");
	RegConsoleCmd("sm_bst", Command_Boost,  "sm_he <player> ");
	HookEvent("decoy_detonate", OnDecoyDetonate);
	

	gPlayerMoney = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
	AutoExecConfig();
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
        
        if (Client && IsClientInGame(Client))
        {
            CreateTimer(0.5, Timer_GiveWeapons, Client, 0);
        }
}

public Action:Timer_GiveWeapons(Handle:Timer, any:client)
{
    GivePlayerItem(client, "item_assaultsuit", 0);
    for(new i = 1; i <= MaxClients; i++)
    {
            onninja[i] = false;
            canuse[i] = true;
            hasNinja[i] = 3;
    }
}

public OnDecoyDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	new String:nome[MAX_NAME_LENGTH];
	GetClientName(attacker, nome, sizeof(nome));
	
	if (team==3) //t team==2 or (team==3) //ct or if (ZR_IsClientZombie(client)) //Zombie  #include <zombiereloaded>
	{
		PrintToChat( client, "\x01[BOOST] \x03 Decoy you got a helping hand from a friend %s", nome);
		Command_Boost(client,  1 );
		
	} 
}

public OnClientDisconnect( id )
{
	bUserHasBoost[ id ] = false;
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/zombie_plague/mario_boost1.wav");
	PrecacheSound("zombie_plague/mario_boost1.wav", true);
	AddFileToDownloadsTable("materials/sprites/blueglow2.vmt");
	AddFileToDownloadsTable("materials/sprites/redglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/greenglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/yellowflare.vmt");
	AddFileToDownloadsTable("materials/sprites/purpleglow1.vmt");
	AddFileToDownloadsTable("materials/sprites/orangecore1.vmt");
	AddFileToDownloadsTable("materials/sprites/lgtning.vmt");
	AddFileToDownloadsTable("materials/sprites/steam2.vmt");
	AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");///
	AddFileToDownloadsTable("materials/sprites/fire.vmt");
	
	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/glow_test02.vmt");

	g_BlueGlowSprite = PrecacheModel("sprites/blueglow2.vmt",true);
	g_RedGlowSprite = PrecacheModel("sprites/redglow1.vmt",true);
	g_GreenGlowSprite = PrecacheModel("sprites/greenglow1.vmt",true);
	g_YellowGlowSprite = PrecacheModel("sprites/yellowflare.vmt",true);
	g_PurpleGlowSprite = PrecacheModel("sprites/purpleglow1.vmt",true);
	g_OrangeGlowSprite = PrecacheModel("sprites/orangecore1.vmt",true);
	g_WhiteGlowSprite = PrecacheModel("sprites/lgtning.vmt",true);
	g_SmokeSprite = PrecacheModel("sprites/steam2.vmt",true);
	g_LightningSprite = PrecacheModel("sprites/tp_beam001.vmt",true);///
	precache_fire_line = PrecacheModel("sprites/fire.vmt",true);
	
	modelindex = PrecacheModel("sprites/laser.vmt",true);
	haloindex = PrecacheModel("sprites/glow_test02.vmt",true);
	
	AddFileToDownloadsTable("sound/zr_facosa/incesivel.mp3");
	PrecacheSound("zr_facosa/incesivel.mp3", true);
	
	AddFileToDownloadsTable("sound/zr_facosa/raio.mp3");
	PrecacheSound("zr_facosa/raio.mp3", true);
	
	AutoExecConfig();
}
public OnTimeCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Time = GetConVarInt(cvar);
}

public Action:Command_Boost(client, args)
{
	if (hasNinja[client] > 0 && canuse[client] && IsPlayerAlive(client))
	{

		if( bUserHasBoost[ client ] )
		{
			PrintToChat( client, "\x01[BOOST] \x03You already have BOOST effects on you." );
			
			return Plugin_Continue;
		}
		
		new money = GetClientMoney( client );
	 
		/*if (ZR_IsClientZombie(client))
		{
		PrintToChat( client, "\x01[BOOST] \x03 Holyshit ZOMBIE NOT !BoosT" );
		return Plugin_Continue;
		}*/
		new team = GetClientTeam(client);
		if (team==2) //t team==2 or (team==3) //ct or if (ZR_IsClientZombie(client)) //Zombie  #include <zombiereloaded>
		{
			PrintToChat( client, "\x01[BOOST] \x03 Holyshit ZOMBIE NOT !BoosT" );
			return Plugin_Continue;
		} 
		hasNinja[client] = hasNinja[client] -1;
	
		bUserHasBoost[ client ] = true;
		SetClientMoney( client, money + 369 );
		CreateTimer( 6.0 , BoostEffectOff, client );

		SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 2.0 );
		SetEntProp( client, Prop_Data, "m_iHealth", GetClientHealth( client ) + 20 );
		SetEntProp( client, Prop_Data, "m_ArmorValue", GetClientArmor( client ) + 20 );

		CreateTimer(0.5, Timer_COR, client, TIMER_REPEAT);
		EmitSoundToAll("zombie_plague/mario_boost1.wav");
		CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
	}
	else
	{
		PrintToChat( client, "\x01[BOOST] \x03You don't have BOOST! You need %d$!", hasNinja[client] );
	}
	
	return Plugin_Continue;
	
}

public Action:Timer_COR(Handle:timer, any:client)
{
static times = 0;
if (g_RoundEnd)
{
times = 0;
return Plugin_Stop;
}
if (times < g_Time)
	{
	//Defalt SetEntityRenderColor(client, 0, 0, 0, 0);//invisivel
	if(times<1){
	SetEntityRenderColor(client, 255, 255, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<2){
	SetEntityRenderColor(client, 250, 130, 0, 500);//cor
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);//ativa
	}else if(times<3){
	SetEntityRenderColor(client, 255, 120, 175, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<4){
	SetEntityRenderColor(client, 0, 255, 255, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<5){
	SetEntityRenderColor(client, 128, 0, 128, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<6){
	SetEntityRenderColor(client, 247, 7, 227, 500);//ssds
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<7){
	SetEntityRenderColor(client, 255, 0, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<8){
	SetEntityRenderColor(client, 0, 255, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<9){
	SetEntityRenderColor(client, 0, 0, 255, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<10){
	SetEntityRenderColor(client, 165, 0, 255, 255);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}
	times++;
	}else{
		times = 0;
		SetEntityRenderColor(client, 255, 255, 255, 255);//visivel
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);//ativador
		return Plugin_Stop;
		}
return Plugin_Continue;
}
	
public Action:BoostEffectOff( Handle:timer, any:id )
{
	bUserHasBoost[ id ] = false;
	SetEntPropFloat( id, Prop_Data, "m_flLaggedMovementValue", 1.0 );
}
stock SetClientMoney( index, money )
{
	if( gPlayerMoney != -1 )
	{
		SetEntData( index, gPlayerMoney, money );
	}
}
stock GetClientMoney( index )
{
	if( gPlayerMoney != -1 )
	{
		return GetEntData( index, gPlayerMoney );
	}
	
	return 0;
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;
	if (g_RoundEnd)
	{
		times = 0;
		return Plugin_Stop;
	}
	
	if (times < g_Time)
	{
		if (IsClientInGame(client))
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			vec[2] += 10;
			new beaconColor[4];
			
			
			//yellow
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 130.0, haloindex, modelindex, 0, 15, 1.1, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Orange
			beaconColor[0] = 250;
			beaconColor[1] = 130;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 120.0, haloindex, modelindex, 0, 10, 1.0, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Pink
			beaconColor[0] = 255;
			beaconColor[1] = 120;
			beaconColor[2] = 175;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 110.0, haloindex, modelindex, 0, 15, 0.9, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Cyan
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 100.0, haloindex, modelindex, 0, 10, 0.8, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Purple
			beaconColor[0] = 128;
			beaconColor[1] = 0;
			beaconColor[2] = 128;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 90.0, modelindex, haloindex, 0, 10, 0.7, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			
			//White
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 80.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			
			//Red
			beaconColor[0] = 255;
			beaconColor[1] = 0;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 70.0, haloindex, modelindex, 0, 15, 0.5, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Green
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 60.0, haloindex, modelindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			//Blue
			beaconColor[0] = 0;
			beaconColor[1] = 0;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 50.0, haloindex, modelindex, 0, 10, 0.3, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			
			
			
			EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);

	// define where the lightning strike ends
			new Float:clientpos[3];
			clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	// get random numbers for the x and y starting positions
			new randomx = GetRandomInt(-500, 500);
			new randomy = GetRandomInt(-500, 500);
	
	// define where the lightning strike starts
			new Float:startpos[3];
			startpos[0] = clientpos[0] + randomx;
			startpos[1] = clientpos[1] + randomy;
			startpos[2] = clientpos[2] + 800;
	
	// define the color of the strike
			new color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
			new Float:dir[3] = {0.0, 0.0, 0.0};
	
			TE_SetupBeamPoints(startpos, vec, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
			TE_SendToAll();
	
			TE_SetupSparks(vec, dir, 5000, 1000);
			TE_SendToAll();
	
			TE_SetupEnergySplash(vec, dir, false);
			TE_SendToAll();
	
			TE_SetupSmoke(vec, g_SmokeSprite, 5.0, 10);
			TE_SendToAll();
			

			
			new Float:vec2[3];
			vec2 = vec;
			vec2[2] = vec[2] + 300.0;
			fire_line(vec,vec2);
			sphere(vec2);
			spark(vec2);
			
			//EmitAmbientSound("zr_facosa/raio.mp3", vec, client, SNDLEVEL_RAIDSIREN);
			times++;

			PrintCenterTextAll("Congratulations, you're alive, may Thor help you %d thunder.", (g_Time - times));
			bUserHasBoost[ client ] = true;
			
		}
	}
	else
	{
		times = 0;
		bUserHasBoost[ client ] = false;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public fire_line(Float:startvec[3],Float:endvec[3])
{
	new color[4]={255,255,255,200};
	TE_SetupBeamPoints( startvec,endvec, precache_fire_line, 0, 0, 0, 0.8, 2.0, 1.0, 1, 0.0, color, 10);
	TE_SendToAll();
}

public sphere(Float:vec[3])
{
	new Float:rpos[3], Float:radius, Float:phi, Float:theta, Float:live, Float: size, Float:delay;
	new Float:direction[3];
	new Float:spos[3];
	new bright = 255;
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	radius = GetRandomFloat(75.0,150.0);
	new rand = GetRandomInt(0,6);
	for (new i=0;i<50;i++)
	{
		delay = GetRandomFloat(0.0,0.5);
		bright = GetRandomInt(128,255);
		live = 2.0 + delay;
		size = GetRandomFloat(0.5,0.7);
		phi = GetRandomFloat(0.0,6.283185);
		theta = GetRandomFloat(0.0,6.283185);
		spos[0] = radius*Sine(phi)*Cosine(theta);
		spos[1] = radius*Sine(phi)*Sine(theta);
		spos[2] = radius*Cosine(phi);
		rpos[0] = vec[0] + spos[0];
		rpos[1] = vec[1] + spos[1];
		rpos[2] = vec[2] + spos[2];

		switch(rand)
		{
			case 0:	TE_SetupGlowSprite(rpos, g_BlueGlowSprite,live, size, bright);
			case 1:	TE_SetupGlowSprite(rpos, g_RedGlowSprite,live, size, bright);
			case 2: TE_SetupGlowSprite(rpos, g_GreenGlowSprite,live, size, bright);
			case 3: TE_SetupGlowSprite(rpos, g_YellowGlowSprite,live, size, bright);
			case 4: TE_SetupGlowSprite(rpos, g_PurpleGlowSprite,live, size, bright);
			case 5: TE_SetupGlowSprite(rpos, g_OrangeGlowSprite,live, size, bright);
			case 6: TE_SetupGlowSprite(rpos, g_WhiteGlowSprite,live, size, bright);
		}
		TE_SendToAll(delay);
	}
}

public spark(Float:vec[3])
{
	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}



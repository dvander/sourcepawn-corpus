/*
	Jail Mod Plugin by Grrrrrrrrrrrrrrrrrrr


	This jail mod was created for servers that have mods like WC3, Superheromod, or any other plugin that allows users to have special powers that must be disabled when they are in jail.
	Of course, this works without any of those mods aswell.

	Enjoy!
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new maxpclients;
#define PLUGIN_VERSION "1.9"
new cColor[2][4]={{50,50,255,200},{255,50,50,200}}
new sprite_beam;
new bool:loadedcellct,bool:loadedcellt;
new Float:tcell[3],Float:ctcell[3];
new String:pmodels[MAXPLAYERS+1][30];
new Handle:celltimer[2];
new pent[MAXPLAYERS+1];
new bool:pinjail[2];
new m_OffsetOriginj;
new Handle:g_CvarEnablej = INVALID_HANDLE,Handle:g_Cvareyes = INVALID_HANDLE;
new Tspawnp[64],CTspawnp[64];
new maxtspawn, maxctspawn;
new bool:attacheyesYN = true,bool:jailmodenabled = true;

public Plugin:myinfo =
{
	name = "Jail Mod",
	author = "Grrrrrrrrrrrrrrrrrrr",
	description = "Players are put in jail and may be rescued",
	version = PLUGIN_VERSION,
	url = "http://efreeforall.com/plugins"
};

public OnPluginStart()
{

	g_CvarEnablej = CreateConVar("jailmod_on", "1", "1 turns the plugin on; 0 is off", FCVAR_NOTIFY);
	g_Cvareyes = CreateConVar("jailmod_eyes", "1", "0 allows players to look around while in Jail", FCVAR_NOTIFY);

       HookEvent("player_death",PlayerDeathEventjail);
	HookEvent("player_spawn",PlayerSpawnEventjail,EventHookMode_Pre);
	HookEvent("round_end",roundendjail);
	HookEvent("round_start",roundstartjail);
	HookEvent("hegrenade_detonate",Event_nade_jail);
	HookEvent("flashbang_detonate",Event_flashb_jail);
	HookEvent("smokegrenade_detonate",Event_smokeg_jail);

	if((m_OffsetOriginj=FindSendPropOffs("CBaseEntity","m_vecOrigin")) == -1) {
		LogError("Could not find offset for CBaseEntity::m_vecOrigin");
	}
}

public OnConfigsExecuted()
{
	//Sprites
	sprite_beam = PrecacheModel("sprites/laserbeam.spr", true);
}

//--------------------- Load spawn points CT & T --------------------------------
public OnMapStart()
{
maxpclients = GetMaxClients();
findctspawnp();
findtspawnp();
}
findctspawnp() {
	new j = 0;
	new entf = -1;
	new lastentf;
	entf = FindEntityByClassname(entf,"info_player_counterterrorist");

	while(entf!=-1)
	{
		CTspawnp[j] = entf;
		j++;

		entf = FindEntityByClassname(entf, "info_player_counterterrorist");
		
		if (entf == lastentf)
		{
			entf = -1;
			break;
		}

		lastentf = entf;
	}

 maxctspawn = (j-1);
}
findtspawnp() {
	new j = 0;
	new entf = -1;
	new lastentf;
	entf = FindEntityByClassname(entf,"info_player_terrorist");

	while(entf!=-1)
	{
		Tspawnp[j] = entf;
		j++;

		entf = FindEntityByClassname(entf, "info_player_terrorist");
		
		if (entf == lastentf)
		{
			entf = -1;
			break;
		}

		lastentf = entf;
	}
 maxtspawn = (j-1);
}

//--------------------- Spawn Jail at a Random spawn point both CT & T --------------------------------
public roundstartjail(Handle:event,const String:name[],bool:dontBroadcast)
{
  attacheyesYN = GetConVarBool(g_Cvareyes);
  jailmodenabled = GetConVarBool(g_CvarEnablej);
  if(jailmodenabled)
  {
   pickjailpoints();
  }
}
pickjailpoints() {
	 //Pick random jail point for t and ct based on a players origin

		new Float:CTorigin[3],Float:Torigin[3];

		if(!loadedcellct) { //spawn jail on CT Side 
			new numct = GetRandomInt(0,maxctspawn);
	           	GetEntDataVector(CTspawnp[numct],m_OffsetOriginj,CTorigin);
			new Handle:CTdata = CreateDataPack();
			WritePackFloat(CTdata, CTorigin[0]);
			WritePackFloat(CTdata, CTorigin[1]);
			WritePackFloat(CTdata, CTorigin[2]);
			WritePackCell(CTdata, 0);

	  		loadedcellct = true;
			ctcell = CTorigin;
			celltimer[0] = CreateTimer(3.0, cellcreate, CTdata,TIMER_REPEAT);
		} 
		if (!loadedcellt) { //spawn jail on T Side
			new numt = GetRandomInt(0,maxtspawn);
	           	GetEntDataVector(Tspawnp[numt],m_OffsetOriginj,Torigin);
			new Handle:Tdata = CreateDataPack();
			WritePackFloat(Tdata, Torigin[0]);
			WritePackFloat(Tdata, Torigin[1]);
			WritePackFloat(Tdata, Torigin[2]);
			WritePackCell(Tdata, 1);

	  		loadedcellt = true;
			tcell = Torigin;
			celltimer[1] = CreateTimer(3.0, cellcreate, Tdata,TIMER_REPEAT);
		}
}
public Action:cellcreate(Handle:timer,Handle:data) {

 //create jail bars one above the other to create the jail cell (jail cell is created every 3 seconds. This way the jail cell may be removed by killing the timer.)
 // jail cell spreads 500x500

	ResetPack(data);
	new Float:start[3],teamcol;
	start[0]= ReadPackFloat(data);
	start[1]= ReadPackFloat(data);
	start[2]= ReadPackFloat(data);
	teamcol = ReadPackCell(data);

	//TE_SetupBeamPoints(bottright, topright, sprite_beam, NULL, 0, 10, Life, 15.0, 15.0, fadelength, 1.0, cColor[teamcol], 0);

	new Float:topleft[3],Float:topright[3],Float:bottright[3],Float:bottleft[3];
	//top-left corner
	topleft[0] = start[0]+250.0;
	topleft[1] = start[1]+250.0;
	topleft[2] = start[2];
	//top-right corner
	topright[0] = start[0]-250.0;
	topright[1] = start[1]+250.0;
	topright[2] = start[2];
	//bottom-left corner
	bottleft[0] = start[0]+250.0;
	bottleft[1] = start[1]-250.0;
	bottleft[2] = start[2];
	//bottom-right corner
	bottright[0] = start[0]-250.0;
	bottright[1] = start[1]-250.0;
	bottright[2] = start[2];

	TE_SetupBeamPoints(topleft, topright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
	TE_SetupBeamPoints(topleft, bottleft, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
	TE_SetupBeamPoints(bottleft, bottright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
	TE_SetupBeamPoints(bottright, topright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();


	//How many bars to add to cell. (bars are horizontal. This stacks more horizontal bars on top of the first one above)
	for (new i=1; i<=3; i++)
	{
		topleft[2] += 25.0;
		topright[2] += 25.0;
		bottleft[2] += 25.0;
		bottright[2] += 25.0;
	
		TE_SetupBeamPoints(topleft, topright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
		TE_SetupBeamPoints(topleft, bottleft, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
		TE_SetupBeamPoints(bottleft, bottright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
		TE_SetupBeamPoints(bottright, topright, sprite_beam, 0, 0, 10, 3.5, 15.0, 15.0, 1, 1.0, cColor[teamcol], 0); TE_SendToAll();
	}

}

//--------------------- Close Jail Cells & Delete Entities --------------------------------
public roundendjail(Handle:event,const String:name[],bool:dontBroadcast)
{
 closejail();
}
public OnMapEnd()
{
 closejail();
}
closejail() 
{
		//remove jail cell (jail cell is created every 3 seconds, so stop that)
		if(celltimer[0]) {
		 KillTimer(celltimer[0]);
		  celltimer[0]=INVALID_HANDLE;
		}
		if(celltimer[1]) {
		 KillTimer(celltimer[1]);
		  celltimer[1]=INVALID_HANDLE;
		}

	//remove jail entities
        for(new x=1;x<=maxpclients;x++)
        {
		if(IsValidEntity(pent[x])&&pent[x]!=0) {
		 if(attacheyesYN) {
		  if(IsClientInGame(x)) {
		   SetClientViewEntity(x, x);
		  }
		 }
		 RemoveEdict(pent[x]);
		 pent[x] = 0;
		}
        }

	//Create new random jail cell position at each round restart
	loadedcellct = false;
	loadedcellt = false;

	//No ones in jail at this moment
	pinjail[0] = false;
	pinjail[1] = false;
}

//--------------------- Save Client Model, Set Client Eyes back to Client, and Delete Client's Entity in Jail --------------------------------
public Action:PlayerSpawnEventjail(Handle:event,const String:name[],bool:dontBroadcast)
{
  if(jailmodenabled)
  {
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	GetClientModel(client, pmodels[client], 30); 	 //Save clients model

	//Fix client back to cleint view & remove jail entity
	if(IsValidEntity(pent[client])&&pent[client]!=0) {
		if(attacheyesYN) {
			SetClientViewEntity(client, client);
		}
  		RemoveEdict(pent[client]);
		pent[client] = 0;
	}
  }
	return Plugin_Continue;
}
//--------------------- Save Client's Entity in Jail & Set Client's View to that Entity --------------------------------
public PlayerDeathEventjail(Handle:event,const String:name[],bool:dontBroadcast)
{
  if(jailmodenabled)
  {
	//Create an entity to symbolize the dead client being in jail. Set dead client view to the entity in jail.

    new userid=GetEventInt(event,"userid");
    new client=GetClientOfUserId(userid);
    if(client>0&&!IsPlayerAlive(client)&&loadedcellct&&loadedcellt)
    {
	new ent = CreateEntityByName("prop_physics_multiplayer");
	if(IsValidEntity(ent))
	{

			//DispatchKeyValue(ent, "physicsmode", "1");
			DispatchKeyValueFloat(ent, "massScale", 500.0);
			DispatchKeyValueFloat(ent, "inertiaScale", 500.0);
			//DispatchKeyValueFloat(ent, "forcetoenablemotion", 350.0);
			
		if(GetClientTeam(client) == 3) {
			 pinjail[0] = true;
			 TeleportEntity(ent,tcell,NULL_VECTOR,NULL_VECTOR);
			 entityplacementinjail(tcell);
		} else {
			 pinjail[1] = true;
			 TeleportEntity(ent,ctcell,NULL_VECTOR,NULL_VECTOR);
			 entityplacementinjail(ctcell);
		}

			PrintCenterText(client,"[Jail] You have been captured and put in Jail!!");
	
			SetEntProp(ent,Prop_Data,"m_takedamage",0,1);
			SetModel(ent,pmodels[client]);
			DispatchSpawn(ent);
			/*
			if(AddVelocity(ent, 400.0)) {
			 SetEntProp(ent, Prop_Send, "movetype", 8, 1);
			}
			*/
			if(attacheyesYN) {
			 SetClientViewEntity(client, ent);
			}
			pent[client] = ent;
	}
    }
  }
}

entityplacementinjail(Float:corigin[3])
{
	new mewho;
        for(new x=1;x<=maxpclients;x++)
        {
		new Float:origin[3];
		mewho = 0;

		if(IsValidEntity(pent[x])&&pent[x]!=0) {
			GetEntDataVector(pent[x],m_OffsetOriginj,origin);
			mewho = pent[x];
		} else if(IsClientInGame(x)) {
			if(IsPlayerAlive(x)) {
				GetClientAbsOrigin(x,origin);
				mewho = x;
			}
		}

		if(mewho>0) {
			if(GetVectorDistance(origin,corigin)<50.0) {
				PrintCenterText(x,"[Jail] You have been moved to make space for a new prisoner.");
				AddVelocity(mewho, 400.0);
			}
		}
        }
}

AddVelocity(any:entt, Float:speed)
{

	new Float:vAngles[3], Float:vReturn[3], Float:Hmultipl, Float:Vmultipl;	

	Hmultipl = GetRandomFloat(-179.0, 179.0);
	Vmultipl = GetRandomFloat(-89.0, 89.0);
	
	vReturn[0] = FloatMul( Cosine( DegToRad(vAngles[1]+Hmultipl)  ) , speed);
	vReturn[1] = FloatMul( Sine( DegToRad(vAngles[1]+Hmultipl)  ) , speed);
	vReturn[2] = FloatMul( Sine( DegToRad(vAngles[0]+Vmultipl)  ) , speed);
		
	TeleportEntity(entt, NULL_VECTOR, NULL_VECTOR, vReturn);
}

//--------------------- Check to See if any player is saving her/his team from Jail --------------------------------
public OnGameFrame()
{	
  if(jailmodenabled)
  {
	//To Do: add a rotation so players may look around while attached to the entities that are in jail

	//watch the jail cells for players coming to rescue their teammates.
	for (new i=1; i<=maxpclients; i++)
	{
	  if(IsClientInGame(i)) {
		if (IsPlayerAlive(i))
		{

		  new Float:corigin[3];
		  GetClientAbsOrigin(i, corigin);

		  if(GetVectorDistance(tcell,corigin)<=260.0&&GetClientTeam(i) == 3&&pinjail[0]) { // save ct's
			saveateamjail(3);
			PrintCenterTextAll("[Jail] The Counter-Terrorists were rescued from jail!!");
			pinjail[0] = false; //No one in jail
		  } else if(GetVectorDistance(ctcell,corigin)<=260.0&&GetClientTeam(i) == 2&&pinjail[1]) { // save t's
			saveateamjail(2);
			PrintCenterTextAll("[Jail] The Terrorists were rescued from jail!!");
			pinjail[1] = false; //No one in jail
		  }

		} else if(IsValidEntity(pent[i])&&pent[i]!=0) {
			new Float:origin[3];
			GetEntDataVector(pent[i],m_OffsetOriginj,origin);

		  if(GetClientTeam(i) == 3&&GetVectorDistance(tcell,origin)>255.0) {
			respawnentin(pent[i],tcell);
		  } else if(GetClientTeam(i) == 2&&GetVectorDistance(ctcell,origin)>255.0) {
			respawnentin(pent[i],ctcell);
		  }
		}
	  }
	}
  }
}
saveateamjail(any:teamsave) {
	for (new i=1; i<=maxpclients; i++)
	{
	  if(IsClientInGame(i)) {
		if (!IsPlayerAlive(i)&&GetClientTeam(i)==teamsave)
		{
			if(IsValidEntity(pent[i])&&pent[i]!=0) {
			       new Float:origin[3];
	           	       GetEntDataVector(pent[i],m_OffsetOriginj,origin);
				RespawnPlayer(i);
				TeleportEntity(i,origin,NULL_VECTOR,NULL_VECTOR);
				pent[i] = 0;
			}
		}
	  }
	}
}
respawnentin(any:ent,Float:cello[3]) {
	if(IsValidEntity(ent)&&ent!=0) {
		TeleportEntity(ent,cello,NULL_VECTOR,NULL_VECTOR);
		AddVelocity(ent, 400.0);
	}
}


//--------------------- Respawn Player & Set Entity Model --------------------------------
public RespawnPlayer(client) //for respawning that player when the player is freed from jail 
{
    CS_RespawnPlayer(client);
}

SetModel(client,const String:model[]) //for setting entities Model
{
  SetEntityModel(client,model);
}

//--------------------- Fix Glitch's -----------------------------------
public Event_nade_jail(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	fixclview(client);
}

public Event_flashb_jail(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	fixclview(client);
}

public Event_smokeg_jail(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	fixclview(client);
}

fixclview(any:client)
{
	if(attacheyesYN) {
		if (!IsPlayerAlive(client))
		{
			if(IsValidEntity(pent[client])&&pent[client]!=0) {
				SetClientViewEntity(client, pent[client]);
			}
		}
	}
}
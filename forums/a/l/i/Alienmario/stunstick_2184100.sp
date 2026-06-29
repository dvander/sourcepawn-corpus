#include <sourcemod>
#include <sdktools>

#define WEAPON "weapon_stunstick"
#define SOUNDLOOP "weapons/physcannon/superphys_hold_loop.wav"
#define BEAMSPRITE "sprites/bluelight1.vmt"
#define HALOSPRITE "sprites/ar2_muzzle1.vmt"
#define HALOSPRITE2 "sprites/strider_blackball.vmt"

#define FORCE  400.0
#define RADIUS  250.0

new BeamSprite;
new HaloSprite;
new HaloSprite2;

new bool:allowed[MAXPLAYERS+1];
new lastButtons[MAXPLAYERS+1];
new PushMode[MAXPLAYERS+1];//0=clients 1=npc 2=all

public OnPluginStart(){
	RegAdminCmd("sm_stunstick", Command_giveweapon, ADMFLAG_KICK, "give a stunstick");
}

public OnMapStart(){
	PrecacheSound(SOUNDLOOP, true);
	BeamSprite = PrecacheModel(BEAMSPRITE);
	HaloSprite = PrecacheModel(HALOSPRITE);
	HaloSprite2 = PrecacheModel(HALOSPRITE2);
}

public Action:Command_giveweapon(client, args){
	GivePlayerItem(client, WEAPON);
	return Plugin_Handled;
}


public OnClientPostAdminCheck(client){
	new AdminId:admin = GetUserAdmin(client);
	if(GetAdminFlag(admin, AdminFlag:Admin_Kick)){
		allowed[client]=true;
	}
}

public OnClientDisconnect_Post(client){
	allowed[client]=false;
	PushMode[client]=0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(allowed[client]){
		decl String:Sweapon[32];
		GetClientWeapon(client, Sweapon, sizeof(Sweapon));
		if(StrEqual(Sweapon, WEAPON)){
			if (buttons & IN_ATTACK2){
				if(! (lastButtons[client] & IN_ATTACK2) ){
					startPush(client);
				}
				Push(client);
				lastButtons[client]=buttons;
				return Plugin_Continue;
			}
			if (lastButtons[client] & IN_RELOAD && !(buttons & IN_RELOAD) ){
				SetHudTextParams(0.85, 0.91, 3.0, 255, 112, 0, 255, 1, 0.0, 0.0, 0.0);
				if(PushMode[client]==0){
					PushMode[client]=1;
					ShowHudText(client, 2, "PushMode: NPC");
				}
				else if(PushMode[client]==1){
					PushMode[client]=2;
					ShowHudText(client, 2, "PushMode: All");
				}
				else if(PushMode[client]==2){
					PushMode[client]=0;
					ShowHudText(client, 2, "PushMode: Clients");
				}
			}
		}
		
		if(lastButtons[client] & IN_ATTACK2){
			endPush(client);
		}
		
		lastButtons[client]=buttons;
	}
	return Plugin_Continue;
}


startPush(client){
	EmitSoundToAll(SOUNDLOOP, client, SNDCHAN_WEAPON, SNDLEVEL_HELICOPTER);
}

endPush(client){
	StopSound(client, SNDCHAN_WEAPON, SOUNDLOOP);
}

Push(client){
	new bool:hit;
	new Float:clientPos[3];
	GetClientEyePosition(client, clientPos);
	
	if(PushMode[client]!=1){
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && i!=client){
				new Float:entPos[3];
				GetClientAbsOrigin(i, entPos);
				
				new Float:distance[3];
				distance[0] = (clientPos[0] - entPos[0]);
				distance[1] = (clientPos[1] - entPos[1]);
				distance[2] = (clientPos[2] - entPos[2]);
				
				if (CheckDistance(distance) && IsClientFacing(client, i))
				{
					hit=true;
					new Float: addAmount[3];
					new Float: ratio[2];
					
					ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));
					ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));

					addAmount[0] = FloatMul( ratio[0]*-1, FORCE);//multiply negative = away
					addAmount[1] = FloatMul( ratio[1]*-1, FORCE);
					addAmount[2] = FORCE/2.0;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, addAmount);

					//TE_SetupBeamPoints(const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
					TE_SetupBeamPoints(clientPos, entPos, BeamSprite, 0, 0, 10, 0.1, 3.0, 10.0, 0, 5.0, {255,255,255,255}, 30);
					TE_SendToAll();
				}
			}
		}
	}
	if (PushMode[client]!=0){
		new maxEnts=GetMaxEntities();
		for (new i = (MaxClients+1); i < maxEnts; i++)
		{
			if (IsEntNetworkable(i))
			{
				new bool:isNpc = bool:(GetEntityFlags(i) & FL_NPC);
				if( PushMode[client]==1 && !isNpc ) continue;
				
				decl Float:entPos[3];
				new offset = GetEntSendPropOffs(i, "m_vecOrigin", true);
				if(offset>0){
					GetEntDataVector(i, offset, entPos);
				}else continue;
				
				decl Float:distance[3];
				distance[0] = (clientPos[0] - entPos[0]);
				distance[1] = (clientPos[1] - entPos[1]);
				distance[2] = (clientPos[2] - entPos[2]);
				
				if (CheckDistance(distance) && IsClientFacing(client, i))
				{
					hit=true;
					decl Float: addAmount[3];
					decl Float: ratio[2];
					
					ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));
					ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));

					addAmount[0] = FloatMul( ratio[0]*-1, FORCE);//multiply negative = away
					addAmount[1] = FloatMul( ratio[1]*-1, FORCE);
					addAmount[2] = FORCE/2.0;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, addAmount);
					if(!isNpc) SetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", Float:{0.0,0.0,0.0});

					//TE_SetupBeamPoints(const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
					TE_SetupBeamPoints(clientPos, entPos, BeamSprite, 0, 0, 10, 0.1, 3.0, 10.0, 0, 5.0, {255,255,255,255}, 30);
					TE_SendToAll();
				}
			}
		}
	}
	if(hit){
		//TE_SetupSparks(clientPos, addAmount, 5, 10);
		//TE_SetupDynamicLight(clientPos, 218, 165, 32, 8, 100.0,0.1,200.0)
		TE_SetupDynamicLight(clientPos, 0, 255, 255, 8, 150.0,0.1,200.0)
		TE_SendToAll();
		
		new Float:size=GetRandomFloat(0.3,0.6);
		new Float:size2=GetRandomFloat(1.5,2.5);
		TE_SetupGlowSprite(clientPos, HaloSprite, 0.2, size2, 255);
		TE_SendToAll();
		TE_SetupGlowSprite(clientPos, HaloSprite2, 0.1, size, 100);
		TE_SendToAll();
	}
}

/**
 * Sets up a Dynamic Light effect
 *
 * @param vecOrigin        Position of the Dynamic Light
 * @param r            r color value
 * @param g            g color value
 * @param b            b color value
 * @param iExponent        ?
 * @param fTime            Duration
 * @param fDecay        Decay of dynamic light
 * @noreturn
 */
stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("r",r);
    TE_WriteNum("g",g);
    TE_WriteNum("b",b);
    TE_WriteNum("exponent",iExponent);
    TE_WriteFloat("m_fRadius",fRadius);
    TE_WriteFloat("m_fTime",fTime);
    TE_WriteFloat("m_fDecay",fDecay);
}


bool:CheckDistance(Float:distance[3]){
	if (SquareRoot( FloatMul(distance[0],distance[0]) + FloatMul(distance[1],distance[1]) + FloatMul(distance[2],distance[2])) <= RADIUS) return true;
	return false;
}

stock bool:IsClientFacing (client, entity, Float:maxAngle=50.0){
	new Float:clientOrigin[3]; new Float:entOrigin[3];
	new Float:eyeAngles[3]; new Float:directAngles[3];
	
	GetClientEyePosition(client, clientOrigin); GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entOrigin);
	// Get the vector from player to the entity
	MakeVectorFromPoints(clientOrigin, entOrigin, directAngles); 
	
	GetVectorAngles(directAngles, directAngles);
	
	GetClientEyeAngles(client, eyeAngles);

	if(GetDifferenceBetweenAngles(eyeAngles, directAngles)>maxAngle){
		return false;
	}
	return true;
}

stock Float:GetDifferenceBetweenAngles(Float:fA[3], Float:fB[3])
{
    new Float:fFwdA[3]; GetAngleVectors(fA, fFwdA, NULL_VECTOR, NULL_VECTOR);
    new Float:fFwdB[3]; GetAngleVectors(fB, fFwdB, NULL_VECTOR, NULL_VECTOR);
    return RadToDeg(ArcCosine(fFwdA[0] * fFwdB[0] + fFwdA[1] * fFwdB[1] + fFwdA[2] * fFwdB[2]));
}
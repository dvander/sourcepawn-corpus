#pragma semicolon 1

float bluepos[3];
float redpos[3];

float blueang[3];
float redang[3];

int BluePortal = 0;
int RedPortal = 0;

bool PortalUseDelay = false;
bool PortalSeperated = false;
bool PortalsActive = false;

int LastUser;
float LastUserPos[3];
float LastUserNewPos[3];

#define PORTAL_MDL "models/props_mall/mall_shopliftscanner.mdl"
#define PORTAL_SND "weapons/defibrillator/defibrillator_use.wav"

public void PortalMapStart()
{
	PortalUseDelay = false;
	PortalSeperated = false;
	PortalsActive = false;
	PrecacheSound(PORTAL_SND);
}


public void Start_Portal(int client)
{
	if (!PortalsActive)
	{
		float pos[3];
		float ang[3];
		GetClientAbsOrigin(client, pos);
		GetClientEyeAngles(client, ang);
		
		ang[0] = NULL_VECTOR[0];
		ang[2] = NULL_VECTOR[2];
		
		BluePortal = CreateBlue(pos,ang);
		RedPortal = CreateRed(pos,ang);
		
		blueang[1] = ang[1];
		redang[1] = ang[1];
		
		PortalsActive = true;
		
		if(IsValidEntRef(RedPortal) && IsValidEntRef(BluePortal))
		{
			PrintToChat(client,"portals entref sucsess");
		}
	}
}
public int CreateBlue(float vec[3],float ang[3])
{
	int Blue;
	Blue = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(Blue, "model", PORTAL_MDL);
	DispatchKeyValue( Blue, "Solid", "6");
	DispatchKeyValueVector( Blue, "Origin", vec );
	DispatchKeyValueVector( Blue, "Angles", ang );
	AcceptEntityInput( Blue , "DisableMotion" );
	DispatchSpawn(Blue);
	//AcceptEntityInput(BluePortal, "EnableCollision");
	SetEntityMoveType(Blue, MOVETYPE_NONE);
	SetEntityRenderColor(Blue, 0, 0, 255, 200);
	SetPortalGlowBlue(Blue);
	
	SDKHook(Blue, SDKHook_Touch, TouchBlue);
	return EntIndexToEntRef(Blue);
	
}
public int CreateRed(float vec[3],float ang[3])
{
	int Red;
	Red = CreateEntityByName("prop_physics_override");
	DispatchKeyValue( Red, "model", PORTAL_MDL);
	DispatchKeyValue( Red, "Solid", "6");
	DispatchKeyValueVector( Red, "Origin", vec );
	DispatchKeyValueVector( Red, "Angles", ang );
	AcceptEntityInput( Red , "DisableMotion" );
	DispatchSpawn(Red);
	//AcceptEntityInput(RedPortal, "EnableCollision");
	SetEntityMoveType(Red, MOVETYPE_NONE);
	SetEntityRenderColor(Red, 255, 0, 0, 200);
	SetPortalGlowRed(Red);
	
	SDKHook(Red, SDKHook_Touch, TouchRed);
	return EntIndexToEntRef(Red);
}


public Action TouchBlue(int entity,int other)
{	
	if(!IsValidEntRef(entity))
	{
		PrintToChatAll("!!!blue portal is broken, cant move");
	}
	
	if(!IsValidEntRef(RedPortal))
	{
		PrintToChatAll("!!!Red portal broken, trying to fix it!!!");
		RedPortal = CreateRed(redpos,redang);
		return;
	}
	// if portals arent indelay and have been seperated and are active
	if(!PortalUseDelay && PortalSeperated && PortalsActive && IsValidClientP(other)&&IsValidEntRef(entity))
	{	
		//PrintToChatAll("%i touch blue %N",entity,other);			
		float BlueClientOrigin[3];
		float BlueClientAngle[3];
		float PlayerVec[3];
		float PlayerAng[3];
		GetEntPropVector(EntRefToEntIndex(RedPortal), Prop_Data, "m_vecOrigin", PlayerVec);
		GetEntPropVector(EntRefToEntIndex(RedPortal), Prop_Data, "m_angRotation", PlayerAng);
		BlueClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[2] = (PlayerVec[2] + 10);

		BlueClientAngle[0] = PlayerAng[0];
		BlueClientAngle[1] = PlayerAng[1];
		BlueClientAngle[2] = PlayerAng[2];
		
		LastUser = other; /// stuck checking stuff
		GetClientAbsOrigin(LastUser,LastUserPos);
		LastUserNewPos = BlueClientOrigin;
		
		TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
		
		EmitSoundToAll(PORTAL_SND);
		
		CreateTimer(1.0, resetportal, 0, 0);
		PortalUseDelay = true;
	}
}

public Action TouchRed(int entity,int other)
{
	if(!IsValidEntRef(entity))
	{
		PrintToChatAll("!!!red portal broke, tell an admin!!!");	
	}
	if(!IsValidEntRef(BluePortal))
	{
		PrintToChatAll("!!!Blue portal broken, trying to fix it!!!");
		BluePortal = CreateBlue(bluepos,blueang);
		return;
	}
	
	// if portals arent indelay and have been seperated and are active
	if(!PortalUseDelay && PortalSeperated && PortalsActive && IsValidClientP(other)&&IsValidEntRef(entity))
	{
		float BlueClientOrigin[3];
		float BlueClientAngle[3];
		float PlayerVec[3];
		float PlayerAng[3];
		GetEntPropVector(EntRefToEntIndex(BluePortal), Prop_Data, "m_vecOrigin", PlayerVec);
		GetEntPropVector(EntRefToEntIndex(BluePortal), Prop_Data, "m_angRotation", PlayerAng);
		BlueClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[2] = (PlayerVec[2] + 10);

		BlueClientAngle[0] = PlayerAng[0];
		BlueClientAngle[1] = PlayerAng[1];
		BlueClientAngle[2] = PlayerAng[2];
		
		LastUser = other; /// stuck checking stuff
		GetClientAbsOrigin(LastUser,LastUserPos);
		LastUserNewPos = BlueClientOrigin;
		
		TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
		
		EmitSoundToAll(PORTAL_SND);
		
		CreateTimer(1.0, resetportal, 0, 0);
		PortalUseDelay = true;
	}
}
public Action resetportal(Handle hTimer, int client)
{
	float CurrentPos[3];
	GetClientAbsOrigin(LastUser,CurrentPos);
	if(GetVectorDistance(CurrentPos,LastUserNewPos) == 0.0)
	{
		//run this if playsers get stuck
		PrintToChatAll("%N was stuck, portal needs to be moved",LastUser);
		TeleportEntity(LastUser, LastUserPos, NULL_VECTOR, NULL_VECTOR);
		
		PortalUseDelay = true;
	}
	else
	{
		PortalUseDelay = false;
	}
}
public void Blue_Move(int client)
{
	float Ang[3];
	int Blue;
	if(IsValidEntRef(BluePortal))
	{
		Blue = EntRefToEntIndex(BluePortal);

		if (GetNewPos(client,bluepos))
		{
			GetClientEyeAngles(client, Ang);
			Ang[0] = NULL_VECTOR[0];
			Ang[1] += 180;
			Ang[2] = NULL_VECTOR[2];
			blueang[1] = Ang[1];
			DispatchKeyValueVector( Blue, "Origin", bluepos );
			DispatchKeyValueVector( Blue, "Angles", Ang );
			
			PortalSeperated = true;
			PortalUseDelay = false;
		}
	}	
	else
	{
		PrintToChat(client,"blue portal was broken, trying to create new one");
		
		if (GetNewPos(client,bluepos))
		{
			GetClientEyeAngles(client, Ang);
			Ang[0] = NULL_VECTOR[0];
			Ang[1] += 180;
			Ang[2] = NULL_VECTOR[2];
			blueang[1] = Ang[1];
			BluePortal = CreateBlue(bluepos,Ang);	
			PortalSeperated = true;
			PortalUseDelay = false;
		}
	}
}
public void Red_Move(int client)
{
	float Ang[3];
	int Red;
	if(IsValidEntRef(RedPortal))
	{
		Red = EntRefToEntIndex(RedPortal);
		if (GetNewPos(client,redpos))
		{
			GetClientEyeAngles(client,Ang);
			Ang[0] = NULL_VECTOR[0];
			Ang[1] += 180;
			Ang[2] = NULL_VECTOR[2];
			redang[1] = Ang[1];

			DispatchKeyValueVector( Red, "Origin", redpos );
			DispatchKeyValueVector( Red, "Angles", Ang );
			
			PortalSeperated = true;
			PortalUseDelay = false;
		}
	}
	else
	{
		PrintToChat(client,"red portal was broken, trying to create new one");
		
		if (GetNewPos(client,redpos))
		{
			GetClientEyeAngles(client, Ang);
			Ang[0] = NULL_VECTOR[0];
			Ang[1] += 180;
			Ang[2] = NULL_VECTOR[2];
			redang[1] = Ang[1];

			RedPortal = CreateRed(redpos,Ang);		
			PortalSeperated = true;
			PortalUseDelay = false;
		}		
	}
}

bool GetNewPos(int client, float vecBuffer[3])
{
	int flags = GetEntityFlags(client);
	
	if (!(flags & FL_ONGROUND))
	{
		PrintToChat(client,"portals cant be placed while in the air");
		return false;
	}
	
	float vPos[3];
	float vAng[3];
	float nPos[3];
	
	GetClientEyePosition(client,vPos);
	GetClientEyeAngles(client,vAng);
	
	if(vAng[0]>50.0) vAng[0] = 50.0;
	if(vAng[0]<-10.0) vAng[0] = -10.0;
	
	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, PortalTraceFilter, client);

	if (TR_DidHit(trace))
	{
		//TR_GetEndPosition(vecBuffer, trace);
		TR_GetEndPosition(nPos, trace);
	
		if (GetVectorDistance(vPos, nPos) > 220)
		{	
			PrintCenterText(client,"out of range");
			return false;
		}
		
		vecBuffer[0]=nPos[0];
		vecBuffer[1]=nPos[1];
		vecBuffer[2]=nPos[2] + 5;
	
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}
public bool PortalTraceFilter(int entity, int contentsMask, int client)
{
	if( entity == client )return false;
	return true;
}
void SetPortalGlowRed(int gun)
{
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_iGlowType", 3);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRange", 0);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRangeMin", 1);
	int red=0;
	int gree=0;
	int blue=0;
	red=200;
	gree=0;
	blue=0;
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

void SetPortalGlowBlue(int gun)
{
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_iGlowType", 3);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRange", 0);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRangeMin", 1);
	int red=0;
	int gree=0;
	int blue=0;
	red=0;
	gree=0;
	blue=200;
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

public bool IsValidClientP(int client)
{
	if (client <= 0 || client > MaxClients)
        return false; 
		
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}
public void Kill_Portals()
{
	if(PortalsActive)
	{
		if(IsValidEntRef(BluePortal))
			AcceptEntityInput( EntRefToEntIndex(BluePortal) , "Kill" );
		
		if(IsValidEntRef(RedPortal))
			AcceptEntityInput( EntRefToEntIndex(RedPortal) , "Kill" );
	
		BluePortal = 0;
		RedPortal = 0;
		
		PortalUseDelay = false;
		PortalSeperated = false;
		PortalsActive = false;
	}
}

#define PARTICLE_TES1			"electrical_arc_01_system"
#define PARTICLE_TES3			"st_elmos_fire"

#define ZAP_1   "ambient/energy/zap1.wav"
#define ZAP_2   "ambient/energy/zap2.wav"

int zombies[31];
bool ZapInfected[31];

int zombiecount;
	
public void StartZap(int client)
{	
	CreateTimer(5.0, DoZap,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action DoZap(Handle timer, int client)
{	
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| ClientData[client][PLAYERDATA:ChosenClass] != view_as<int>(TESLA))
			return Plugin_Stop;
			
	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{	return Plugin_Continue; }
	
	FindZombies();
	RequestFrame(CheckZombies, client);
	return Plugin_Continue; 
}

void FindZombies()
{
	int ent;
	zombiecount = 0;
	while ((ent = FindEntityByClassname(ent,  "infected" )) != -1 && zombiecount < 30)
	{
		zombies[zombiecount++] = ent;
		ZapInfected[zombiecount] = false;
	} 
}
int IsZombie(int ent)
{
	if(ent > 0 && IsValidEntity(ent))
	{
        char strClassName[64];
        GetEntityClassname(ent, strClassName, sizeof(strClassName));
        if(StrContains(strClassName, "infected") != -1)
		{
			return ent;
		}
    }
    return 0;
}
public void CheckZombies(int client)
{
	int zapcount = 0;
	float pos[3];
	GetClientAbsOrigin(client,pos);
	
	for (int z = 0; z <= zombiecount; z++)
	{
		int target = IsZombie(zombies[z]);		
		
		float tpos[3];
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", tpos);	
		float dist = GetVectorDistance(pos, tpos);
		if(dist < 600.0)
		{
			//DataPack pack = new DataPack(); 
			//pack.WriteCell(client); 
			//pack.WriteCell(target); 
			//pack.Reset(); 
			//RequestFrame(ZapZombie,pack);
				
			ZapInfected[z] = true;
			RequestFrame(ZapZombie, client);
				
			zapcount++;
		}
		if(zapcount >5)
			return;
	}	
}
	
public void ZapZombie(int client)
{   
	//DataPack data = view_as<DataPack>(thing); 
    //int client = data.ReadCell(); 
    //int zombie = data.ReadCell(); 
	float pos[3];
	float tpos[3];
	GetClientAbsOrigin(client,pos);
	for (int z = 0; z <= zombiecount; z++)
	{
		if(ZapInfected[z])
		{
			int target = IsZombie(zombies[z]);		
			if(target != 0)
			{

				GetEntPropVector(target , Prop_Data, "m_vecOrigin", tpos);	
		
				CreateElectricArc(pos,tpos);
				switch(GetRandomInt(1,2))
				{
					case 1:
						EmitSoundToAll(ZAP_1,target ,SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0);
					case 2:
						EmitSoundToAll(ZAP_2,target ,SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0);
				}
				//AcceptEntityInput(target, "BecomeRagdoll");	
				DealDamage(target , client, 1.0, 8);
				//DealDamage(zombie, client, 40.0, 256);
			}
		}		
	}
}
stock void CreateElectricArc( float vPos[3], float vEndPos[3] )
{	
 	char sTemp[32];
	int iTarget = 0;
	int iType = GetRandomInt( 0, 1 );
	
	iTarget = CreateEntityByName( "info_particle_target");
	
	Format( sTemp, sizeof sTemp, "cptarget%d", iTarget );
	DispatchKeyValue( iTarget, "targetname", sTemp );
	TeleportEntity( iTarget, vEndPos, NULL_VECTOR, NULL_VECTOR );
	ActivateEntity( iTarget );

	int particle = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue( particle, "effect_name", iType == 0 ? PARTICLE_TES1 : PARTICLE_TES3 );
	DispatchKeyValue(particle, "cpoint1", sTemp);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	
	InputKill( iTarget, 1.0 ); 	// Duración del objetivo falso.
	InputKill( particle, 0.8 ); // Duración de la partícula.
}

public void PrecacheZapStuff()
{
	PrecacheParticle(PARTICLE_TES1);
	PrecacheSound(ZAP_1);
	PrecacheSound(ZAP_2);
}

void InputKill(int entity, float time)
{
	static char temp[40];
	Format(temp, sizeof(temp), "OnUser4 !self:Kill::%f:-1", time);
	SetVariantString(temp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
}

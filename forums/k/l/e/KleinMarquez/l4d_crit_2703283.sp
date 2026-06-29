
public PlVers:__version =
{
	version = 5,
	filevers = "1.8.0.5969",
	date = "09/03/2019",
	time = "22:05:22"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new ConVar:cvarCritChance;
new ConVar:cvarCritDamageMin;
new ConVar:cvarCritDamageMax;
new ConVar:cvarCritForce;
new ConVar:cvarCritPrint;
new damagechance;
new damage;
new damagebonus;
new damageshow;
new health;
public Plugin:myinfo =
{
	name = "[L4D] Critical Shot",
	description = "Damage done to special infected will have chance to become critical",
	author = "[E]c, TK",
	version = "1.1",
	url = ""
};
public void:__ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return void:0;
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:DegToRad(Float:angle)
{
	return angle * 3.1415927 / 180;
}

void:SetEntityHealth(entity, amount)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_iHealth");
		}
		gotconfig = true;
	}
	new String:cls[64];
	new PropFieldType:type;
	new offset;
	if (!GetEntityNetClass(entity, cls, 64))
	{
		ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
		return void:0;
	}
	offset = FindSendPropInfo(cls, prop, type, 0, 0);
	if (0 >= offset)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return void:0;
	}
	if (type == PropFieldType:2)
	{
		SetEntDataFloat(entity, offset, float(amount), false);
	}
	else
	{
		SetEntProp(entity, PropType:0, prop, amount, 4, 0);
	}
	return void:0;
}

public void:OnPluginStart()
{
	HookEvent("player_hurt", SHurtDamage, EventHookMode:1);
	cvarCritChance = CreateConVar("sm_critical_chance", "3", "Critical Chance Percentage (Default 5)", 0, true, 0.0, false, 0.0);
	cvarCritDamageMin = CreateConVar("sm_critical_min", "2", "How many times minimum damage increases when crit (Default 2)", 0, true, 0.0, false, 0.0);
	cvarCritDamageMax = CreateConVar("sm_critical_max", "10", "How many times maximum damage increases when crit (Default 10)", 0, true, 0.0, false, 0.0);
	cvarCritForce = CreateConVar("sm_critical_force", "100", "Drop critical hit victim (Default is 100)", 0, true, 0.0, false, 0.0);
	cvarCritPrint = CreateConVar("sm_critical_print", "1", "Show critical damage in chat", 0, true, 0.0, false, 0.0);
	AutoExecConfig(true, "l4d_crit", "sourcemod");
	return void:0;
}

public Action:SHurtDamage(Event:event, String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	new victim = GetClientOfUserId(GetEventInt(event, "userid", 0));
	new var1;
	if (!victim || !attacker)
	{
		return Action:0;
	}
	new var2;
	if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
	{
		if (IsClientInGame(attacker))
		{
			new TempChance = GetRandomInt(0, 100);
			if (GetConVarInt(cvarCritChance) > TempChance)
			{
				damagechance = GetRandomInt(GetConVarInt(cvarCritDamageMin), GetConVarInt(cvarCritDamageMax));
				health = GetClientHealth(victim);
				damage = GetEventInt(event, "dmg_health", 0);
				damagebonus = damagechance * damage;
				damageshow = damagebonus + damage;
				if (GetConVarInt(cvarCritPrint))
				{
					PrintToChat(attacker, "\x01 Critical!\x03 %i\x01 damage", damageshow);
				}
				Knockback(attacker, victim, GetConVarFloat(cvarCritForce), 1.5, 2.0);
				CreateTimer(0.01, apply, victim, 0);
			}
		}
	}
	return Action:0;
}

public Action:apply(Handle:timer, any:victim)
{
	if (0 >= health - damagebonus)
	{
		KillVictim();
	}
	else
	{
		SetEntityHealth(victim, health - damagebonus);
	}
	return Action:0;
}

void:Knockback(client, target, Float:power, Float:powHor, Float:powVec)
{
	new Float:HeadingVector[3] = 0.0;
	new Float:AimVector[3] = 0.0;
	GetClientEyeAngles(client, HeadingVector);
	AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * power * powHor;
	AimVector[1] = Sine(DegToRad(HeadingVector[1])) * power * powHor;
	new Float:current[3] = 0.0;
	GetEntPropVector(target, PropType:1, "m_vecVelocity", current, 0);
	new Float:resulting[3] = 0.0;
	resulting[0] = current[0] + AimVector[0];
	resulting[1] = current[1] + AimVector[1];
	resulting[2] = power * powVec;
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
	return void:0;
}

void:KillVictim()
{
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3)
				{
					ForcePlayerSuicide(i);
				}
			}
		}
		i++;
	}
	return void:0;
}


stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);

	if(TR_DidHit(trace)){
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

stock RotateYaw( Float:angles[3], Float:degree )
{
    decl Float:direction[3], Float:normal[3];
    GetAngleVectors( angles, direction, NULL_VECTOR, normal );
    
    new Float:sin = Sine( degree * 0.01745328 );
    new Float:cos = Cosine( degree * 0.01745328 );
    new Float:a = normal[0] * sin;
    new Float:b = normal[1] * sin;
    new Float:c = normal[2] * sin;
    new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
    new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
    new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
    direction[0] = x;
    direction[1] = y;
    direction[2] = z;
    
    GetVectorAngles( direction, angles );

    decl Float:up[3];
    GetVectorVectors( direction, NULL_VECTOR, up );

    new Float:roll = GetAngleBetweenVectors( up, normal, direction );
    angles[2] += roll;
}

stock GetClientAimTarget2(client, bool:only_clients = true)
{
    new Float:eyeloc[3], Float:ang[3];
    GetClientEyePosition(client, eyeloc);
    GetClientEyeAngles(client, ang);
    TR_TraceRayFilter(eyeloc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, client);
	
    new entity = TR_GetEntityIndex();

    if (only_clients){
        if (entity >= 1 && entity <= MaxClients){
            return entity;
		}
    }else{
        if (entity > 0){
            return entity;
		}
    }
    return -1;
}

stock Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
    decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
    NormalizeVector( direction, direction_n );
    NormalizeVector( vector1, vector1_n );
    NormalizeVector( vector2, vector2_n );
    new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;
    GetVectorCrossProduct( vector1_n, vector2_n, cross );
    
    if ( GetVectorDotProduct( cross, direction_n ) < 0.0 ){
        degree *= -1.0;
    }

    return degree;
}

stock GetEntityRenderColor2(entity, color[4])
{
	new offset = GetEntSendPropOffs(entity, "m_clrRender");
	
	if (offset <= 0){
		ThrowError("GetEntityColor not supported by this mod");
	}
	
	color[0] = GetEntData(entity, offset, 1);
	color[1] = GetEntData(entity, offset + 1, 1);
	color[2] = GetEntData(entity, offset + 2, 1);
	color[3] = GetEntData(entity, offset + 3, 1);
}

stock SetEntityColor(entity, color[4] = {-1, ...})
{
	new dummy_color[4]; 
	
	GetEntityRenderColor2(entity, dummy_color);
	
	for (new i = 0; i <= 3; i++){
		if (color[i] != -1){
			dummy_color[i] = color[i];
		}
	}
	
	SetEntityRenderColor(entity, dummy_color[0], dummy_color[1], dummy_color[2], dummy_color[3]);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
}

stock bool:StringToColor(const String:str[], color[4], defvalue = -1)
{
	new bool:result = false;
	new String:Splitter[4][64];
	if (ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) == 4 && String_IsNumeric(Splitter[0]) && String_IsNumeric(Splitter[1]) && String_IsNumeric(Splitter[2]) && String_IsNumeric(Splitter[3])){
		color[0] = StringToInt(Splitter[0]);
		color[1] = StringToInt(Splitter[1]);
		color[2] = StringToInt(Splitter[2]);
		color[3] = StringToInt(Splitter[3]);
		result = true;
	}else{
		color[0] = defvalue;
		color[1] = defvalue;
		color[2] = defvalue;
		color[3] = defvalue;
	}
	return result;
}

stock ColorToString(const color[4], String:buffer[], size)
{
	Format(buffer, size, "%d %d %d %d", color[0], color[1], color[2], color[3]);
}

stock bool:String_IsNumeric(const String:str[])
{
	new x=0;
	new numbersFound=0;

	if (str[x] == '+' || str[x] == '-'){
		x++;
	}

	while (str[x] != '\0'){
		if (IsCharNumeric(str[x])){
			numbersFound++;
		}else{
			return false;
		}
		x++;
	}
	if (!numbersFound){
		return false;
	}
	return true;
}

stock PrintHudText(client, String:text[])
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer, text); 
	EndMessage();
}
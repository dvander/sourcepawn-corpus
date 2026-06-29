#pragma     semicolon 1
#include    <sourcemod>
#include    <sdktools>
#include    <cstrike>
#include    <morecolors>
#include    <drugshop>
#define     PREFIX "{blueviolet}[{hotpink}DrugShop{blueviolet}]{aliceblue}"
#define     PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 
{
    name =          "[DrugShop] CT Confiscate",
    author =        "JasonBourne && Kolapsicle",
    description =   "CT's can confiscate drugs if they catch a trade being made.",
    version =       PLUGIN_VERSION,
    url =           "https://forums.alliedmods.net/showthread.php?t=255946"
};


public OnPluginStart ()
{
    LoadTranslations("drugshop.phrases.txt");    
}


public OnDrugBuy(const String:auth[], const String:drug_name[], drug, num_drugs)
{
    if (num_drugs > 0)
    {
        DrugTrade(auth, drug, num_drugs);
    }
}


public OnDrugSell(const String:auth[], const String:drug_name[], drug, num_drugs)
{
    if (num_drugs > 0)
    {
        DrugTrade(auth, drug, num_drugs);
    }
}


DrugTrade(const String:auth[], drug, num_drugs)
{
    new t = GetClientFromAuth(auth);
    if (t > 0 && GetClientTeam(t) == CS_TEAM_T)
    {
        new ct = -1;
        new Float:dist = -1.0;
        new Float:test_dist = 0.0;
        
        if (t > 0)
        {
            for (new i = 1; i <= MAXPLAYERS + 1; i++)
            {   
                if (ClientIsValid(i) && i != t &&  GetClientTeam(i) == CS_TEAM_CT)
                {
                    test_dist = GetEntitiesDistance(i, t);
                    if (ClientCanSeeClient(i, t) && IsTargetInSightRange(i, t) &&(test_dist < dist || dist == -1))
                    {
                        dist = test_dist;
                        ct = i;
                    }
                }
            }
        }

        if (ct != -1)
        {
            new String:auth2[64];
            GetClientAuthString(ct, auth2, 64);
            DrugShop_AddDrugs(auth, drug, -num_drugs);
            DrugShop_AddDrugs(auth2, drug, num_drugs);
            
            new String:dg_name[32];
            DrugShop_GetDrugName(dg_name, drug, sizeof(dg_name));
            new String:buffer[255];
            Format(buffer, sizeof(buffer), "%s %T", PREFIX, "confiscate", LANG_SERVER, ct, num_drugs, dg_name, t);
            CPrintToChatAll("%s", buffer);
        }
    }
}


GetClientFromAuth(const String:auth[])
{
    for (new i = 1; i <= MAXPLAYERS + 1; i++)
    {   
        if (ClientIsValid(i))
        {
            new String:auth2[64];
            GetClientAuthString(i, auth2, sizeof(auth2));
            if (StrEqual(auth, auth2))
            {
                return i;
            }
        }
    }
    
    return -1;
}


bool:ClientCanSeeClient(client, target, Float:distance = 0.0, Float:height = 50.0)
{

        new Float:vClientPosition[3], Float:vTargetPosition[3];
        
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", vClientPosition);
        vClientPosition[2] += height;
        
        GetClientEyePosition(target, vTargetPosition);
        
        if (distance == 0.0 || GetVectorDistance(vClientPosition, vTargetPosition, false) < distance)
        {
            new Handle:trace = TR_TraceRayFilterEx(vClientPosition, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);

            if(TR_DidHit(trace))
            {
                CloseHandle(trace);
                return (false);
            }
            
            CloseHandle(trace);

            return (true);
        }
        return false;
}


public bool:Base_TraceFilter(entity, contentsMask, any:data)
{
    if(entity != data)
    {
        return (false);
    }
    
    return (true);
} 


public Float:GetEntitiesDistance(ent1, ent2)
{
    new Float:orig1[3];
    GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
    
    new Float:orig2[3];
    GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

    return GetVectorDistance(orig1, orig2);
}  


bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	if(!ClientIsValid(client))
		ThrowError("Client is not Alive.");
	if(!ClientIsValid(target))
		ThrowError("Target is not Alive.");
		
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}
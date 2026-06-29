#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new Handle:precachedModels;
new haloIndex;

#define this_version "1.4.02"
public Plugin:myinfo =
{
    name = "[Port] wcs_effects",
    author = "joshtrav",
    description = "Port of the ES_Tools addon specifically effects",
    version = this_version,
    url = "http://www.joinWCS.com"
};

public OnPluginStart()
{
    CreateConVar("wcs_effects", this_version, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    precachedModels = CreateTrie();
    
    RegServerCmd("est_effect", EffectCall);
    RegServerCmd("est_effect_01", EffectCall);
    RegServerCmd("est_effect_02", EffectCall);
    RegServerCmd("est_effect_03", EffectCall);
    RegServerCmd("est_effect_04", EffectCall);
    RegServerCmd("est_effect_05", EffectCall);
    RegServerCmd("est_effect_06", EffectCall);
    RegServerCmd("est_effect_07", EffectCall);
    RegServerCmd("est_effect_08", EffectCall);
    RegServerCmd("est_effect_09", EffectCall);
    RegServerCmd("est_effect_10", EffectCall);
    RegServerCmd("est_effect_11", EffectCall);
    RegServerCmd("est_effect_12", EffectCall);
    RegServerCmd("est_effect_13", EffectCall);
    RegServerCmd("est_effect_14", EffectCall);
    RegServerCmd("est_effect_18", EffectCall);
    RegServerCmd("est_effect_24", EffectCall);
}

public OnMapStart()
{
    ClearTrie(precachedModels);
    haloIndex = 0;
}

public Action:EffectCall(args)
{
    new argsc = GetCmdArgs()
    if(argsc < 4)
        return Plugin_Handled;
    
    new String:arg[128], String:cFilter[128], String:arg0[32], String:arg1[128], String:arg2[128], String:arg3[128], String:arg4[128], String:argString[1024];
    new effectInt, modelIndex;
    
    GetCmdArg(0, arg0, sizeof(arg0));
    if(StrContains(arg0, "_effect_", false) != -1)
    {
        if(StrContains(arg0, "est_effect_", false) != -1)
            ReplaceString(arg0, sizeof(arg0), "est_effect_", "");
        
        effectInt = StringToInt(arg0) + 100;
    }
    else
    {
        GetCmdArg(1, arg1, sizeof(arg1));
        effectInt = StringToInt(arg1);
    }    
    
    
    new i = 0;
    
    if(effectInt >= 100)
    {
        if(effectInt != 118 && effectInt != 111 && effectInt != 110 && effectInt != 109 && effectInt != 101)
        {
            GetCmdArg(3, arg3, sizeof(arg3));
            if(!GetTrieValue(precachedModels, arg3, modelIndex))
            {    
                modelIndex = PrecacheModel(arg3);
                SetTrieValue(precachedModels, arg3, modelIndex);
            }
            i = 4;
        }
        else
        {
            i = 3;
        }
        
        GetCmdArg(1, arg1, sizeof(arg1))
        cFilter = arg1;
        
    }
    else
    {
        GetCmdArg(4, arg4, sizeof(arg4));
        if(!GetTrieValue(precachedModels, arg4, modelIndex))
        {    
            modelIndex = PrecacheModel(arg4);
            SetTrieValue(precachedModels, arg4, modelIndex);
        }
        
        GetCmdArg(2, arg2, sizeof(arg2));
        cFilter = arg2;
        i = 5;
    }
        
   
    new Handle:pack = CreateDataPack()
    for (new j = i; j<=args; j++)
    {
        GetCmdArg(j, arg, sizeof(arg));
        WritePackString(pack, arg);
    }
    
    switch(effectInt)
    {
        case 124:
        {
            if (argsc != 5)
            {    
                PrintToServer("est_Effect_24 <player Filter> <delay> <model> <Position 'X,Y,Z'> <reversed>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect124(pack, cFilter, modelIndex)
        }
        case 118:
        {
            if (argsc != 10)
            {    
                PrintToServer("est_Effect_18 <player Filter> <delay> <Position 'X,Y,Z'> <R> <G> <B> <exponent> <radius> <time> <decay>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect118(pack, cFilter)
        }
        case 114:
        {
            if (argsc != 8)
            {    
                PrintToServer("est_Effect_14 <player Filter> <delay> <model> <Min 'X,Y,Z'> <Max 'X,Y,Z'> <heigth> <count> <speed>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect114(pack, cFilter, modelIndex)
        }
        case 113:
        {
            if (args != 5)
            {
                PrintToServer("est_Effect_13 <player Filter> <delay> <decal> <origin 'X,Y,Z'> <target entity index>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect113(pack, cFilter, modelIndex)
        }
        case 112:
        {
            if (args != 11)
            {
                PrintToServer("est_Effect_12 <player Filter> <delay> <model> <origin 'X,Y,Z'> <angle 'Pitch,Yaw,Roll'> <Size 'X,Y,Z'> <Velocity 'X,Y,Z'> <Randomization> <count> <time> <flags>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect112(pack, cFilter, modelIndex)
        }
        case 111:
        {
            if (args != 9)
            {
                PrintToServer("est_Effect_11 <player Filter> <delay> <origin 'X,Y,Z'> <direction 'X,Y,Z'> <R> <G> <B> <A> <Amount>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect111(pack, cFilter)
        }
        case 110:
        {
            if (args != 9)
            {
                PrintToServer("est_Effect_10 <player Filter> <delay> <origin 'X,Y,Z'> <direction 'X,Y,Z'> <R> <G> <B> <A> <Size>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect110(pack, cFilter)
        }
        case 109:
        {
            if (args != 5)
            {
                PrintToServer("est_Effect_09 <player Filter> <delay> <model> <points> <rgPoints 'X,Y,Z'>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect109(pack, cFilter)
        }
        case 108:
        {
            if (argsc != 17)
            {    
                PrintToServer("est_Effect_08 <player Filter> <delay> <model> <center 'X,Y,Z'> <Start Radius> <End Radius> <framerate> <life> <width> <spread> <amplitude> <R> <G> <B> <A> <speed> <flags>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect108(pack, cFilter, modelIndex)
        }
        case 107:
        {
            if (args != 15)
            {
                PrintToServer("est_Effect_07 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <width> <spread> <amplitude> <R> <G> <B> <A> <speed>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect107(pack, cFilter, modelIndex)
        }
        case 106:
        {
            if (argsc != 16)
            {    
                PrintToServer("est_Effect_06 <player Filter> <delay> <model> <start position 'X,Y,Z'> <end position 'X,Y,Z'> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect106(pack, cFilter, modelIndex)
        }
        case 105:
        {
            if (args != 16)
            {		
                PrintToServer("est_effect_05 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect105(pack, cFilter, modelIndex)
        }
        case 104:
        {
            if (argsc != 12)
            {    
                PrintToServer("est_Effect_04 <player Filter> <delay> <model> <Follow ent> <life> <start width> <end width> <fade distance> <R> <G> <B> <A>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect104(pack, cFilter, modelIndex)
        }
        case 103:
        {
            if (args != 16)
            {
                PrintToServer("est_Effect_03 <player Filter> <delay> <model> <start ent> <end ent> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect103(pack, cFilter, modelIndex)
        }
        case 102:
        {
            if (args != 18)
            {
                PrintToServer("est_Effect_02 <player Filter> <delay> <model> <start ent> <start position 'X,Y,Z'> <end ent> <end position 'X,Y,Z'> <framerate> <life> <start width> <end width> <fade distance> <amplitude> <R> <G> <B> <A> <speed>")
                CloseHandle(pack);
                return Plugin_Stop;
            }
            ProcessEffect102(pack, cFilter, modelIndex)
        }
        case 101:
        {
            if (args != 4)
            {
                PrintToServer("est_Effect_01 <player Filter> <delay> <position 'X,Y,Z'> <direction 'X,Y,Z'>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect101(pack, cFilter)
        }
        case 11:
        {
            if (argsc != 10)
            {    
                PrintToServer("est_Effect 11 <player Filter> <delay> <model> <x> <y> <z> <life> <size> <brightness>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect11(pack, cFilter, modelIndex)
        }
        case 10:
        {    
            if (argsc != 18)
            {    
                PrintToServer("est_Effect 10 <player Filter> <delay> <model> <x> <y> <z> <start radius> <end radius> <life> <width> <spread> <amplitude> <Red> <Green> <Blue> <Alpha> <speed>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect10(pack, cFilter, modelIndex)
        }
        case 7:
        {
            if (argsc != 9)
            {    
                PrintToServer("est_Effect 7 <player Filter> <delay> <model> <x> <y> <z> <scale> <framerate>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect7(pack, cFilter, modelIndex)
        }
        case 4:
        {
            if (argsc != 13)
            {    
                PrintToServer("est_Effect 4 <player Filter> <delay> <model> <userid> <life> <width> <end width> <time to fade> <Red> <Green> <Blue> <Alpha>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect4(pack, cFilter, modelIndex)
        }
        case 3:
        {
            if (argsc != 17)
            {    
                PrintToServer("est_Effect 3 <player Filter> <delay> <model> (start <X> <Y> <Z>) (end <X> <Y> <Z>) <life> <width> <end width> <Red> <Green> <Blue> <Alpha>");
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect3(pack, cFilter, modelIndex)
        }
        case 1:
        {
            if (args != 5)
            {
                PrintToServer("est_Effect 1 <player Filter> <delay> <position 'X,Y,Z'> <direction 'X,Y,Z'>")
                CloseHandle(pack);
                return Plugin_Handled;
            }
            ProcessEffect1(pack, cFilter, modelIndex)
        }
        default:
        {
            GetCmdArgString(argString, sizeof(argString));            
            LogError(argString);
            CloseHandle(pack);
            return Plugin_Handled;
        }
    }
    return Plugin_Handled;
}

stock ProcessEffect124(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
    
    TE_Start("Large Funnel");
    TE_WriteFloat("m_vecOrigin[0]", effectVector1[0]);
    TE_WriteFloat("m_vecOrigin[1]", effectVector1[1]);
    TE_WriteFloat("m_vecOrigin[2]", effectVector1[2]);
    TE_WriteNum("m_nModelIndex", modelIndex);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nReversed", StringToInt(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect118(Handle:pack, String:cFilter[])
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
    
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin", effectVector1);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("r", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("g", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("b", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("exponent", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fRadius", StringToFloat(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fTime", StringToFloat(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fDecay", StringToFloat(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect114(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
    
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0]);
    effectVector2[1] = StringToFloat(vecExplode[1]);
    effectVector2[2] = StringToFloat(vecExplode[2]);
    
    TE_Start("Bubbles");
    TE_WriteVector("m_vecMins", effectVector1);
    TE_WriteVector("m_vecMaxs", effectVector2);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fHeight", StringToFloat(buffer));
    TE_WriteNum("m_nModelIndex", modelIndex);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nCount", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fSpeed", StringToFloat(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect113(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
		
    TE_Start("BSP Decal")
    TE_WriteVector("m_vecOrigin", effectVector1);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nEntity", StringToInt(buffer));
    TE_WriteNum("m_nIndex", modelIndex);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect112(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0]);
    effectVector2[1] = StringToFloat(vecExplode[1]);
    effectVector2[2] = StringToFloat(vecExplode[2]);
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector3[3];
    effectVector3[0] = StringToFloat(vecExplode[0]);
    effectVector3[1] = StringToFloat(vecExplode[1]);
    effectVector3[2] = StringToFloat(vecExplode[2]);
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector4[3];
    effectVector4[0] = StringToFloat(vecExplode[0]);
    effectVector4[1] = StringToFloat(vecExplode[1]);
    effectVector4[2] = StringToFloat(vecExplode[2]);
		
    TE_Start("Break Model");
    TE_WriteVector("m_vecOrigin", effectVector1);
    TE_WriteFloat("m_angRotation[0]", effectVector2[0]);
    TE_WriteFloat("m_angRotation[1]", effectVector2[1]);
    TE_WriteFloat("m_angRotation[2]", effectVector2[2]);
    TE_WriteVector("m_vecSize", effectVector3);
    TE_WriteVector("m_vecVelocity", effectVector4);
    TE_WriteNum("m_nModelIndex", modelIndex);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nRandomization", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nCount", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fTime", StringToFloat(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFlags", StringToInt(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect111(Handle:pack, String:cFilter[])
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0]);
    effectVector2[1] = StringToFloat(vecExplode[1]);
    effectVector2[2] = StringToFloat(vecExplode[2]);
		
    TE_Start("Blood Stream");
    TE_WriteFloat("m_vecOrigin[0]", effectVector1[0]);
    TE_WriteFloat("m_vecOrigin[1]", effectVector1[1]);
    TE_WriteFloat("m_vecOrigin[2]", effectVector1[2]);
    TE_WriteVector("m_vecDirection", effectVector2);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("r", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("g", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("b", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("a", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nAmount", StringToInt(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect110(Handle:pack, String:cFilter[])
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
		
    ReadPackString(pack, buffer, sizeof(buffer))
    ExplodeString(buffer, ",",  vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0]);
    effectVector2[1] = StringToFloat(vecExplode[1]);
    effectVector2[2] = StringToFloat(vecExplode[2]);
		
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new size = StringToInt(buffer);
		
    TE_SetupBloodSprite(effectVector1, effectVector2, colorArray, size, 0, 0) ;
    //SprayModel, BloodDropModel)
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect109(Handle:pack, String:cFilter[])
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    TE_Start("BeamSpline");
    TE_WriteNum("m_nPoints", StringToInt(buffer));
		
    ReadPackString(pack, buffer, sizeof(buffer))
    ExplodeString(buffer,",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
		
    TE_WriteVector("m_vecPoints", effectVector1);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect108(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
    
    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", effectVector1);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_flStartRadius", StringToFloat(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_flEndRadius", StringToFloat(buffer));
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nHaloIndex", haloIndex);
    TE_WriteNum("m_nStartFrame", 0);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFrameRate", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fLife", StringToFloat(buffer));
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer)
    TE_WriteFloat("m_fWidth", widthF);
    TE_WriteFloat("m_fEndWidth", widthF);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFadeLength", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fAmplitude", StringToFloat(buffer));
    
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("r", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("g", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("b", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("a", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nSpeed", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFlags", StringToInt(buffer));
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect107(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    TE_Start("BeamRing");
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nHaloIndex", haloIndex);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nStartEntity", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nEndEntity", StringToInt(buffer));
    TE_WriteNum("m_nStartFrame", 0);
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFrameRate", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fLife", StringToFloat(buffer));
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    TE_WriteFloat("m_fWidth", widthF);
    TE_WriteFloat("m_fEndWidth", widthF);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFadeLength", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fAmplitude", StringToFloat(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("r", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("g", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("b", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("a", StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nSpeed", StringToInt(buffer));
    TE_WriteNum("m_nFlags", 0);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect106(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0]);
    effectVector1[1] = StringToFloat(vecExplode[1]);
    effectVector1[2] = StringToFloat(vecExplode[2]);
    
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]));
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0]);
    effectVector2[1] = StringToFloat(vecExplode[1]);
    effectVector2[2] = StringToFloat(vecExplode[2]);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new frameRate = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new fadeLength = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:amplitudeF = StringToFloat(buffer)
    
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new speed = StringToInt(buffer);
    
    TE_SetupBeamPoints(effectVector1, effectVector2, modelIndex, haloIndex, 0, frameRate, lifeF, widthF, endWidthF, fadeLength, amplitudeF, colorArray, speed);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect105(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    ReadPackString(pack, buffer, sizeof(buffer))
    new startEntity = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new endEntity = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new frameRate = StringToInt(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new fadeLength = StringToInt(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:amplitudeF = StringToFloat(buffer);
    
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new speed = StringToInt(buffer);
				
    TE_SetupBeamLaser(startEntity, endEntity, modelIndex, haloIndex, 0, frameRate, lifeF, widthF, endWidthF, fadeLength, amplitudeF, colorArray, speed);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect104(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    ReadPackString(pack, buffer, sizeof(buffer))
    new entity = StringToInt(buffer);
    PrintToServer(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new fadeLength = StringToInt(buffer);
    
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
    
    TE_SetupBeamFollow(entity, modelIndex, haloIndex, lifeF, widthF, endWidthF, fadeLength, colorArray)
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect103(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    TE_Start("BeamEnts")
    TE_WriteNum("m_nHaloIndex", haloIndex)
    TE_WriteNum("m_nModelIndex", modelIndex)
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nStartEntity", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nEndEntity", StringToInt(buffer))
    TE_WriteNum("m_nStartFrame", 0)
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFrameRate", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fLife", StringToFloat(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fWidth", StringToFloat(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fEndWidth", StringToFloat(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nFadeLength", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteFloat("m_fAmplitude", StringToFloat(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("r", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("g", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("b", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("a", StringToInt(buffer))
    ReadPackString(pack, buffer, sizeof(buffer))
    TE_WriteNum("m_nSpeed", StringToInt(buffer))
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect102(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    new startEntity = StringToInt(buffer);
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0])
    effectVector1[1] = StringToFloat(vecExplode[1])
    effectVector1[2] = StringToFloat(vecExplode[2])
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new endEntity = StringToInt(buffer);
		
    ReadPackString(pack, buffer, sizeof(buffer))
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0])
    effectVector2[1] = StringToFloat(vecExplode[1])
    effectVector2[2] = StringToFloat(vecExplode[2])
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new frameRate = StringToInt(buffer)
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer)
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer)
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer)
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new fadeLength = StringToInt(buffer)
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:amplitudeF = StringToFloat(buffer)
		
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer)
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer)
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer)
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer)
		
    ReadPackString(pack, buffer, sizeof(buffer))
    new speed = StringToInt(buffer)
		
    TE_Start("BeamEntPoint")
    TE_WriteNum("m_nHaloIndex", haloIndex)
    TE_WriteNum("m_nModelIndex", modelIndex)
    TE_WriteNum("m_nStartFrame", 0)
    TE_WriteNum("m_nFrameRate", frameRate)
    TE_WriteFloat("m_fLife", lifeF)
    TE_WriteFloat("m_fWidth", widthF)
    TE_WriteFloat("m_fEndWidth", endWidthF)
    TE_WriteNum("m_nFadeLength", fadeLength)
    TE_WriteFloat("m_fAmplitude", amplitudeF)
    TE_WriteNum("m_nSpeed", speed)
    TE_WriteNum("r", colorArray[0])
    TE_WriteNum("g", colorArray[1])
    TE_WriteNum("b", colorArray[2])
    TE_WriteNum("a", colorArray[3])
    TE_WriteNum("m_nStartEntity", startEntity)
    TE_WriteNum("m_nEndEntity", endEntity)
    TE_WriteVector("m_vecStartPoint", effectVector1)
    TE_WriteVector("m_vecEndPoint", effectVector2)
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect101(Handle:pack, String:cFilter[])
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0])
    effectVector1[1] = StringToFloat(vecExplode[1])
    effectVector1[2] = StringToFloat(vecExplode[2])
		
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0])
    effectVector2[1] = StringToFloat(vecExplode[1])
    effectVector2[2] = StringToFloat(vecExplode[2])
		
    TE_SetupArmorRicochet(effectVector1, effectVector2);
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect11(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    new Float:effectVector1[3];
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[0] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[1] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[2] = StringToFloat(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:sizeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new brightness = StringToInt(buffer);
    
    TE_SetupGlowSprite(effectVector1, modelIndex, lifeF, sizeF, brightness);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect10(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    new Float:effectVector1[3];
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[0] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[1] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[2] = StringToFloat(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:startRadiusF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endRadiusF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new spread = StringToInt(buffer); // frameRate
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:amplitudeF = StringToFloat(buffer);
        
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new speed = StringToInt(buffer);
    
    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", effectVector1);
    TE_WriteFloat("m_flStartRadius", startRadiusF);
    TE_WriteFloat("m_flEndRadius", endRadiusF);
    TE_WriteNum("m_nModelIndex", modelIndex);
    TE_WriteNum("m_nHaloIndex", haloIndex);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", lifeF);
    TE_WriteFloat("m_fWidth", widthF);
    TE_WriteFloat("m_fEndWidth", widthF);
    TE_WriteFloat("m_fAmplitude", amplitudeF);
    TE_WriteNum("r", colorArray[0]);
    TE_WriteNum("g", colorArray[1]);
    TE_WriteNum("b", colorArray[2]);
    TE_WriteNum("a", colorArray[3]);
    TE_WriteNum("m_nSpeed", speed);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", spread);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect7(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    new Float:effectVector1[3];
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[0] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[1] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[2] = StringToFloat(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:scaleF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new frameRate = StringToInt(buffer);
    
    TE_SetupSmoke(effectVector1, modelIndex, scaleF, frameRate);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect4(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    ReadPackString(pack, buffer, sizeof(buffer))
    new client = GetClientOfUserId(StringToInt(buffer));
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new fadeLength = StringToInt(buffer);
    
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
    
    TE_SetupBeamFollow(client, modelIndex, haloIndex, lifeF, widthF, endWidthF, fadeLength, colorArray)
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
stock ProcessEffect3(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128];
                
    new Float:effectVector1[3];
    ReadPackString(pack, buffer, sizeof(buffer))
    PrintToServer(buffer)
    effectVector1[0] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[1] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector1[2] = StringToFloat(buffer);
    
    new Float:effectVector2[3];
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector2[0] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector2[1] = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    effectVector2[2] = StringToFloat(buffer);
    
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:lifeF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:widthF = StringToFloat(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    new Float:endWidthF = StringToFloat(buffer);
    
    new colorArray[4];
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[0] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[1] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[2] = StringToInt(buffer);
    ReadPackString(pack, buffer, sizeof(buffer))
    colorArray[3] = StringToInt(buffer);
            
    TE_SetupBeamPoints(effectVector1, effectVector2, modelIndex, haloIndex, 0, 0, lifeF, widthF, endWidthF, 0, 0.0, colorArray, 0)
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}
            
stock ProcessEffect1(Handle:pack, String:cFilter[], const modelIndex)
{
    ResetPack(pack);
    new String:buffer[128],String:vecExplode[3][128];
                
    ReadPackString(pack, buffer, sizeof(buffer));
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector1[3];
    effectVector1[0] = StringToFloat(vecExplode[0])
    effectVector1[1] = StringToFloat(vecExplode[1])
    effectVector1[2] = StringToFloat(vecExplode[2])
		
    ReadPackString(pack, buffer, sizeof(buffer))
    ExplodeString(buffer, ",", vecExplode, sizeof(vecExplode), sizeof(vecExplode[]))
    new Float:effectVector2[3];
    effectVector2[0] = StringToFloat(vecExplode[0])
    effectVector2[1] = StringToFloat(vecExplode[1])
    effectVector2[2] = StringToFloat(vecExplode[2])
		
    TE_SetupArmorRicochet(effectVector1, effectVector2);
    
    CloseHandle(pack);
    ProcessFilter(cFilter)
}

stock ProcessFilter(String:cFilter[])
{
    new pCount, toSend[MaxClients];
    if(StrEqual(cFilter, "#a", false))
    {
        TE_SendToAll()
    }
    else if(StrEqual(cFilter, "#t", false))
    {
        
        pCount = 0
        for (new i = 1; i < MaxClients; i++)
            if(IsClientInGame(i) && !IsFakeClient(i))
                if (GetClientTeam(i) == 2)
                    toSend[pCount++] = i
        if(pCount > 0)
            TE_Send(toSend, pCount)
    }
    else if(StrEqual(cFilter, "#ct", false))
    {
        
        pCount = 0
        for (new i = 1; i < MaxClients; i++)
            if(IsClientInGame(i) && !IsFakeClient(i))
                if (GetClientTeam(i) == 3)
                    toSend[pCount++] = i
        if(pCount > 0)
            TE_Send(toSend, pCount)
    }
    else if(StrEqual(cFilter, "#d", false))
    {
        
        pCount = 0
        for (new i = 1; i < MaxClients; i++)
            if(IsClientInGame(i) && !IsPlayerAlive(i) && !IsFakeClient(i))
                toSend[pCount++] = i
        if(pCount > 0)
            TE_Send(toSend, pCount)
    }
    else
    {
        new userid = StringToInt(cFilter);
        new client = GetClientOfUserId(userid);
        if(client > 0)
            if(IsClientInGame(client))
                TE_SendToClient(client);
    }
}
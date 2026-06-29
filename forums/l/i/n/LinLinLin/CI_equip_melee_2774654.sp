/*
    very thanks for Dragokas's help."prop_dynamic_ornament" works well.
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.2"

//#define W_CHAINSAW "models/weapons/melee/w_chainsaw.mdl" chainsaw need adjust itself,unwieldy
#define W_BAT "models/weapons/melee/w_bat.mdl"
#define W_CRICKET_BAT "models/weapons/melee/w_cricket_bat.mdl"
#define W_CROWBAR "models/weapons/melee/w_crowbar.mdl"
#define W_ELECTRIC_GUITAR "models/weapons/melee/w_electric_guitar.mdl"
#define W_FIREAXE "models/weapons/melee/w_fireaxe.mdl"
#define W_FRYINGPAN "models/weapons/melee/w_frying_pan.mdl"
#define W_GOLFCLUB "models/weapons/melee/w_golfclub.mdl"
#define W_KANATA "models/weapons/melee/w_katana.mdl"
#define W_MACHETE "models/weapons/melee/w_machete.mdl"
#define W_TONFA "models/weapons/melee/w_tonfa.mdl"
#define W_SHOVEL "models/weapons/melee/w_shovel.mdl"
#define W_PITCHFORK "models/weapons/melee/w_pitchfork.mdl"
#define W_KNIFE "models/w_models/weapons/w_knife_t.mdl"

#define M_TANK "models/infected/hulk.mdl"
char NZ_weapon[13][64] = 
{
    W_BAT,
    W_CRICKET_BAT,
    W_CROWBAR,
    W_ELECTRIC_GUITAR,
    W_FIREAXE,
    W_FRYINGPAN,
    W_GOLFCLUB,
    W_KANATA,
    W_MACHETE,
    W_TONFA,
    W_SHOVEL,
    W_PITCHFORK,
    W_KNIFE,
};

ConVar g_Scale;
ConVar g_Switchtype;
ConVar g_Random;
float g_fScale;
int g_iSwitchtype;
int g_iRandom;
//don't edit this.I adjust it so long. 
float g_leftpos[3] = {-5.0,-2.0,0.0};
float g_rightpos[3] = {-10.0,-2.0,0.0};
float g_ang[3] = {180.0,180.0,0.0};
public Plugin myinfo =
{
	name = "僵尸随机手持近战",
	author = "萌新/幸运星",
	description = "僵尸随机手持近战",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

public void OnPluginStart()
{
    g_Scale = CreateConVar("L4D2_Scale_NZweapon", "1.2",  "僵尸的近战模型的缩放倍率|Scale the weapon in CI,1.2 is good.you can try what you want.",FCVAR_NOTIFY);
    g_Switchtype = CreateConVar("L4D2_Switch_InfectedType", "1",  "选择生成僵尸的类型(1=all,2=only CI,3=only special CI)|Choose which type of CI can have melee",FCVAR_NOTIFY);
    g_Random = CreateConVar("L4D2_Random_CreateMeleeInfected", "100",  "生成近战僵尸的概率|Random of create melee CI.40 is equal to 40%",FCVAR_NOTIFY,true,0.0,true,100.0);
    HookConVarChange(g_Scale,Cvar_HookConvarChange);
    HookConVarChange(g_Switchtype,Cvar_HookConvarChange);
    HookConVarChange(g_Random,Cvar_HookConvarChange);

    HookEvent("player_death",Event_PlayerDeath);
    AutoExecConfig(true,"Miuwiki_CI_equip_melee");
}
public void OnMapStart()
{
    //vmodel代表手上的时候模型。
    //wmodel代表第三人称视角时候的模型。
    PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
    PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
    PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
    PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
    PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
    PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
    PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
    PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
    PrecacheModel( "models/weapons/melee/w_shovel.mdl", true );
    PrecacheModel( "models/weapons/melee/w_pitchfork.mdl", true );
    PrecacheModel( "models/w_models/weapons/w_knife_t.mdl", true );
    PrecacheModel( "models/infected/hulk.mdl", true );
}
public void OnConfigsExecuted()
{
    GetCvars();
}
public void Cvar_HookConvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}
void GetCvars()
{
    g_fScale = g_Scale.FloatValue;
    g_iSwitchtype = g_Switchtype.IntValue;
    g_iRandom = g_Random.IntValue;
}

public Action Event_PlayerDeath(Event event,const char []name,bool dontBroadcast)
{
    int entity = GetEventInt(event,"entityid");
    char classname[64];
    GetEntityClassname(entity,classname,sizeof(classname));
    if(StrEqual(classname,"infected"))
    {
        //entity （僵尸实体） => ornament (隐形坦克实体) => KillHierarchy 子实体

        char targetname[32];
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));//获取entity的targetname
        int ornament = StringToInt(targetname);

        if(ornament != 0 && IsValidEntity(ornament))
        {
            AcceptEntityInput(ornament,"KillHierarchy");
        }
    }
}
public void OnEntityCreated(int entity, const char []classname)
{
    if(StrEqual(classname,"infected"))
    {
        int ref = EntIndexToEntRef(entity);
        SDKHook(ref,SDKHook_SpawnPost,SDK_SpawnPost);
    }
}
public Action SDK_SpawnPost(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        if(g_iSwitchtype == 1)
        {
            RequestFrame(CreateWeaponForNZ,entity);
        }
        else if(g_iSwitchtype == 2)
        {
            char model[64];
            GetEntPropString(entity,Prop_Data,"m_ModelName",model,sizeof(model));
            if( StrContains(model,"riot.mdl") != -1
                ||StrContains(model,"ceda.mdl") != -1
                ||StrContains(model,"clown.mdl") != -1
                ||StrContains(model,"mud.mdl") != -1
                ||StrContains(model,"roadcrew.mdl") != -1
                ||StrContains(model,"jimmy.mdl")!= -1
                ||StrContains(model,"fallen_survivor.mdl") != -1
                )return;//here return
            else
            {
                int refence = EntIndexToEntRef(entity);
                RequestFrame(CreateWeaponForNZ,refence);
            }
        }
        else if(g_iSwitchtype == 3)
        {
            char model[64];
            GetEntPropString(entity,Prop_Data,"m_ModelName",model,sizeof(model));
            if( StrContains(model,"riot.mdl") != -1
                ||StrContains(model,"ceda.mdl") != -1
                ||StrContains(model,"clown.mdl") != -1
                ||StrContains(model,"mud.mdl") != -1
                ||StrContains(model,"roadcrew.mdl") != -1
                ||StrContains(model,"jimmy.mdl")!= -1
                ||StrContains(model,"fallen_survivor.mdl") != -1
                )
            {
                int refence = EntIndexToEntRef(entity);
                RequestFrame(CreateWeaponForNZ,refence);
            }
        }
    }
}
void CreateWeaponForNZ(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        int rand = GetRandomInt(1,100);
        if(rand > g_iRandom)return;

        int ornament = CreateEntityByName("prop_dynamic_ornament");//该实体将生成一个实体，它的模型将会依照父实体的骨骼进行调整。
        int ent_weapon = CreateEntityByName("prop_dynamic_override");
        if(ornament == -1 || ent_weapon == -1)return;

        //将子实体索引设置为父实体（小僵尸）的targetname，通过父实体的targetname来取回子实体。
        char temp[16];
        IntToString(ornament,temp,sizeof(temp));
        DispatchKeyValue(entity, "targetname", temp);

        //这里是ornament
        DispatchKeyValue(ornament,"model",M_TANK);
        DispatchSpawn(ornament);
        ActivateEntity(ornament);
        SetVariantString("!activator");
        AcceptEntityInput(ornament, "SetParent", entity);
        SetVariantString("!activator");
        AcceptEntityInput(ornament, "SetAttached", entity);
        AcceptEntityInput(ornament, "TurnOff");
        
        //这里开始为ent_weapon
        ActivateEntity(ent_weapon);
        SetVariantString("!activator");
        AcceptEntityInput(ent_weapon, "SetParent", ornament);
        SetVariantString("!activator");
        AcceptEntityInput(ent_weapon, "SetAttached", ornament);

        int hand = GetRandomInt(1,2);
        hand == 1 ? SetVariantString("rhand"):SetVariantString("lhand");//坦克的手部实体绑定点
        AcceptEntityInput(ent_weapon, "SetParentAttachment",ornament);//该函数就会传送实体

        int random_model = GetRandomInt(0,sizeof(NZ_weapon)-1);
        DispatchKeyValue(ent_weapon,"model",NZ_weapon[random_model]);

        SetEntProp(ent_weapon, Prop_Send, "m_CollisionGroup", 2);
        SetEntPropFloat(ent_weapon , Prop_Send,"m_flModelScale", g_fScale);
        DispatchSpawn(ent_weapon);

        //右手武器增加180度；
        /*pos[0] 垂直向上 */
        // float ang[3] = {0.0},lpos[3] = {0.0},rpos[3] = {0.0};
        // GetEntPropVector(ent_weapon,Prop_Send,"m_angRotation",ang);
        // ang[0] += 180.0;
        // ang[1] += 180.0;
        // lpos[0] -= 5.0;
        // lpos[1] -= 2.0;
        // rpos[0] -= 10.0;
        // rpos[1] -= 2.0;
        hand == 1 ? TeleportEntity(ent_weapon,g_rightpos,g_ang,NULL_VECTOR):TeleportEntity(ent_weapon,g_leftpos,NULL_VECTOR,NULL_VECTOR);
    }
}

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

/* model define */
#define Car1_MODEL 	"models/props_vehicles/longnose_truck.mdl"
#define Car2_MODEL 	"models/props_vehicles/bus01_2.mdl"
#define Car3_MODEL 	"models/props_vehicles/racecar.mdl"
#define Car4_MODEL 	"models/props_foliage/swamp_rock01.mdl"
#define Car5_MODEL 	"models/infected/boomer.mdl"

public Plugin:myinfo = 
{
	name = "Tank throw vehicles",
	author = "xiluo",
	description = "TankThrowCar",
	version = "any"
}

public OnMapStart()
{	
	PrecacheModel(Car1_MODEL, true);
	PrecacheModel(Car2_MODEL, true);
	PrecacheModel(Car3_MODEL, true);
	PrecacheModel(Car4_MODEL, true);
	PrecacheModel(Car5_MODEL, true);
}

public OnEntityCreated(entity)//系统函数，当一个实体被创建时
{
	if(entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity))
		return;//如果实体不是有效的并且插件设置开启值不为1并且不存在玩家时返回
	
	decl String:EntityName[128];
	
	GetEdictClassname(entity, EntityName, sizeof(EntityName)); //获取创建物体的名字
	
	
	if(StrEqual(EntityName, "tank_rock", false))
	{
		CreateCar(entity);
	}
}

public CreateCar(parent)
{
	decl Float:origin[3],Float:ang[3], String:tname[60];

	GetEntPropVector(parent, Prop_Data, "m_vecOrigin", origin);	
	GetEntPropVector(parent, Prop_Data, "m_angRotation", ang);
	
	
	
	new Car =  CreateEntityByName("prop_dynamic_override");//创建一个实体的类名CreateEntityByName("prop_dynamic_override")
		
	new i=GetRandomInt(1, 5);//GetRandomInt(1, 5);
	if(i==1)
	{
		DispatchKeyValue(Car,"model",Car1_MODEL);
	}else if(i==2)
	{
		DispatchKeyValue(Car,"model",Car2_MODEL);
	}else if(i==3)
	{
		DispatchKeyValue(Car,"model",Car3_MODEL);
	}else if(i==4)
	{
		Car = CreateEntityByName("prop_physics_override");//物理实体 将会以真正的车子大范围击倒幸存者
		DispatchKeyValue(Car,"model",Car4_MODEL);
		//PrintHintTextToAll("Tank 发疯了扔出了超级石头，全体人员迅速躲避！！");
	}else if(i==5)
	{
		DispatchKeyValue(Car,"model",Car5_MODEL);
	}
	ang[0]=0.0;
	origin[2]-=30;//30	
	origin[0]+=5;//5		
	SetEntityMoveType(Car, MOVETYPE_NOCLIP);	//设置实体的移动标志,没有重力，没有碰撞，仍然有速度MOVETYPE_NOCLIP
	DispatchSpawn(Car);//在游戏中产生一个实体。
	
	TeleportEntity(Car, origin, ang, NULL_VECTOR);//传送一个实体,第二个参数新位置,第三个参数是角度,最后一个参数是默认原先速度
	
	SetEntProp(Car, Prop_Send, "m_iGlowType", 3);//轮廓的范围类
	SetEntProp(Car, Prop_Send, "m_nGlowRange", 50000);//可见范围
	SetEntProp(Car, Prop_Send, "m_glowColorOverride", (GetRandomInt(-32767,32767) * 128));//设置实体轮廓
	
	Format(tname, sizeof(tname), "target%d", parent);//将第三个参数格式化于tname字符串中，parent为实体变量 
	DispatchKeyValue(parent, "targetname", tname);	
	DispatchKeyValue(Car, "parentname", tname);		
	SetVariantString(tname);//在全局变量中设置一个字符串
	AcceptEntityInput(Car, "SetParent", Car, Car, 0);//AcceptEntityInput(Car, "SetParent", Car, Car, 0);//调用实体上的命名输入方法。完成(成功与否)后，当前的全局变量被重新输入
		
}
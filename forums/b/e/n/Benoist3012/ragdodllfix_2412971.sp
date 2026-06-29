#include <sourcemod>
 
 public Plugin myinfo = 
{
	name			= "[TF2] Glitched Ragdoll Fix!",
	author			= "Benoist3012",
	description		= "Fix glitched ragdoll.",
	version			= "0.1",
	url				= "http://steamcommunity.com/id/Benoist3012/"
};

public void OnEntityCreated(int iEntity,const char[] strClassname)
{
	if(StrEqual(strClassname,"tf_ragdoll"))
	{
		SetEntPropFloat(iEntity, Prop_Send, "m_flHeadScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(iEntity, Prop_Send, "m_flHandScale", 1.0);
	}
}
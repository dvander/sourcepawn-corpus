#include <tf2_stocks>
public TF2_OnConditionAdded(client, TFCond:cond)
{
	if (cond != TFCond_Cloaked) return;
	SetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime", 0.0);
}

public TF2_OnConditionRemoved(client, TFCond:cond)
{
	if (cond != TFCond_Cloaked) return;
	SetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime", 0.0);
}
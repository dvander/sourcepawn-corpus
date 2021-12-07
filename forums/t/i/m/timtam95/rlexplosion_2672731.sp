#include <sdktools>

public OnPluginStart() {  

	AddTempEntHook("TFExplosion", TEHook);

}
  
public Action TEHook(const char[] te_name, const int[] Players, int numClients, float delay) {

	if (TE_ReadNum("m_iWeaponID") == 22) {

		float f_vecOrigin[3];
		f_vecOrigin[0] = TE_ReadFloat("m_vecOrigin[0]");
		f_vecOrigin[1] = TE_ReadFloat("m_vecOrigin[1]");
		f_vecOrigin[2] = TE_ReadFloat("m_vecOrigin[2]");

		new particle = CreateEntityByName("info_particle_system");

		if (IsValidEdict(particle)) {

			DispatchKeyValue(particle , "start_active", "0");
			DispatchKeyValue(particle, "effect_name", "xms_snowburst");
        		DispatchSpawn(particle);
        		TeleportEntity(particle, f_vecOrigin, NULL_VECTOR, NULL_VECTOR);
        		ActivateEntity(particle);
        		AcceptEntityInput(particle, "start");

		}

		return Plugin_Handled;
	}

	return Plugin_Continue;

}
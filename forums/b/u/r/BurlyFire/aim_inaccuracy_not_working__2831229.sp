// Definir constantes para el umbral de velocidad y desviación en la puntería
#define SPEED_THRESHOLD 300.0  // Umbral de velocidad en unidades (ajustar según sea necesario)
#define AIM_DEVIATION 5.0      // Desviación máxima en grados (ajustar según sea necesario)
#define PI 3.14159265358979323846

// Función para convertir un vector en ángulos (yaw, pitch)
public VectorToAngles(const float:vector[3], float:angles[3])
{
    // Calcular el pitch (ángulo en el eje X) y yaw (ángulo en el eje Y)
    angles[0] = Math_Atan2(vector[2], FloatAbs(vector[0])) * (180.0 / PI);  // Calcular pitch
    angles[1] = Math_Atan2(vector[1], vector[0]) * (180.0 / PI);             // Calcular yaw

    // El roll (ángulo en el eje Z) se establece a 0, ya que no se utiliza en este caso
    angles[2] = 0.0;
}

// Función para introducir inexactitud cuando se apunta a un objeto en movimiento rápido
public Action:OnBotAimBotToTarget(bot, target)
{
    // Obtener la velocidad del objetivo (por ejemplo, un jugador u objeto)
    float targetSpeed = GetEntitySpeed(target);
    
    // Verificar si la velocidad del objetivo supera el umbral
    if (targetSpeed > SPEED_THRESHOLD)
    {
        // Introducir desviación aleatoria en la puntería
        float deviationAngle = GetRandomFloat(-AIM_DEVIATION, AIM_DEVIATION);
        
        // Aplicar la desviación en la dirección de la puntería del bot
        ApplyAimDeviation(bot, target, deviationAngle);
    }
    else
    {
        // Si el objetivo no se mueve rápido, se apunta normalmente
        AimAtTarget(bot, target);
    }

    return Plugin_Continue;
}

// Función para calcular la velocidad de la entidad
float:GetEntitySpeed(entity)
{
    float velocity[3];
    GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
    
    // Calcular la velocidad como la magnitud del vector de velocidad
    return FloatAbs(velocity[0]) + FloatAbs(velocity[1]) + FloatAbs(velocity[2]);
}

// Función para aplicar desviación en la puntería
ApplyAimDeviation(bot, target, deviationAngle)
{
    // Obtener los ángulos de la vista de la entidad (bot)
    float botAim[3];
    GetEntPropVector(bot, Prop_Data, "m_angEyeAngles", botAim); // Obtener los ángulos de la vista (yaw, pitch)

    // Añadir la desviación al ángulo de puntería
    botAim[1] += deviationAngle; // Añadir desviación al ángulo yaw (horizontal)
    
    // Establecer los nuevos ángulos de la vista del bot
    SetEntPropVector(bot, Prop_Data, "m_angEyeAngles", botAim); // Establecer los nuevos ángulos (yaw, pitch)
}

// Función para apuntar directamente al objetivo (sin desviación)
AimAtTarget(bot, target)
{
    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);
    
    // Calcular el ángulo de puntería necesario para mirar al objetivo
    float aimAngles[3];
    VectorToAngles(targetPos, aimAngles);  // Convertir la posición en ángulos
    
    // Establecer la puntería del bot hacia la posición del objetivo
    SetEntPropVector(bot, Prop_Data, "m_angEyeAngles", aimAngles); // Establecer los ángulos de puntería
}

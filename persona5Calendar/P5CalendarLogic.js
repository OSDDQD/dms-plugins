.pragma library

/**
 * Maps Open-Meteo WMO weather codes (0..99) to Persona 5 OpenWeather icon codes.
 *
 * P5 assets provide:
 *   01d/01n: Clear sky
 *   02d/02n: Few clouds
 *   03d/03n: Scattered clouds
 *   04d/04n: Broken/overcast clouds
 *   09d/09n: Shower rain / Drizzle
 *   10d/10n: Rain
 *   11d/11n: Thunderstorm
 *   13d/13n: Snow
 *   50d/50n: Mist / Fog
 */
function getWeatherIconCode(wCode, isDay) {
    const suffix = isDay ? "d" : "n";
    const code = Number(wCode);

    switch (code) {
        case 0:
        case 1:
            return "01" + suffix;
        case 2:
            return "02" + suffix;
        case 3:
            return "04" + suffix;
        case 45:
        case 48:
            return "50" + suffix;
        case 51:
        case 53:
        case 55:
        case 56:
        case 57:
            return "09" + suffix;
        case 61:
        case 63:
        case 65:
        case 66:
        case 67:
            return "10" + suffix;
        case 71:
        case 73:
        case 75:
        case 77:
            return "13" + suffix;
        case 80:
        case 81:
        case 82:
            return "09" + suffix;
        case 85:
        case 86:
            return "13" + suffix;
        case 95:
        case 96:
        case 99:
            return "11" + suffix;
        default:
            return "01" + suffix;
    }
}

/**
 * Calculates Persona 5 Time of Day (1..6)
 *
 * Persona 5 ToD assets:
 *   1: Evening (Late Night)
 *   2: Early Morning
 *   3: Morning
 *   4: Daytime (or After School)
 *   5: Afternoon
 *   6: Evening
 */
function getTimeOfDay(hour, mode, weatherService, date) {
    if (mode === "solar" && weatherService && typeof weatherService.getCurrentSunTime === "function") {
        try {
            const sunInfo = weatherService.getCurrentSunTime(date || new Date());
            if (sunInfo && typeof sunInfo.periodIndex === "number") {
                const p = sunInfo.periodIndex;
                if (p <= 2) return 2; // Dawn twilights -> Early Morning
                if (p <= 5) return 3; // Sunrise / Morning -> Morning
                if (p === 6) return 4; // Afternoon noon -> Daytime
                if (p === 7) return 5; // Golden hour -> Afternoon
                if (p <= 9) return 6; // Sunset / Dusk -> Evening
                return 1;              // Night -> Evening / Late Night
            }
        } catch (e) {
            // fallback to game hour
        }
    }

    // Default: P5 Game Hours
    // < 1: 1 (Evening / Late Night)
    // < 7: 2 (Early Morning)
    // < 11: 3 (Morning)
    // < 14: 4 (Daytime)
    // < 19: 5 (Afternoon)
    // < 21: 6 (Evening)
    // >= 21: 1 (Evening)
    const h = Number(hour);
    if (h < 1) return 1;
    if (h < 7) return 2;
    if (h < 11) return 3;
    if (h < 14) return 4;
    if (h < 19) return 5;
    if (h < 21) return 6;
    return 1;
}

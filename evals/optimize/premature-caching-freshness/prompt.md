---
name: optimize-premature-caching-freshness
description: Recognize when "optimization" would break correctness; identify measurements needed
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I want to speed up weather lookups in my app. Users check the weather multiple times per session, and each lookup calls a remote weather API. Here's the code:

```typescript
// src/lib/weather.ts
import { getWeatherFromAPI } from '@/services/weather-api';

export async function getWeather(latitude: number, longitude: number) {
  // Every call hits the API, no caching
  const weather = await getWeatherFromAPI(latitude, longitude);
  return weather;
}
```

In my component:

```typescript
// src/components/WeatherWidget.tsx
export function WeatherWidget({ lat, lon }: { lat: number; lon: number }) {
  const [weather, setWeather] = useState(null);

  useEffect(() => {
    getWeather(lat, lon).then(setWeather);
  }, [lat, lon]); // Re-runs when location changes

  return <div>{weather?.temp}°</div>;
}
```

Users often view the same location multiple times in a session. I'd like to cache results to avoid repeated API calls. What caching strategy would you recommend? Should I use sessionStorage, in-memory cache, or something else? How long should results be cached?

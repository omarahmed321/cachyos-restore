#!/usr/bin/env python3
import urllib.request
import json
import datetime
import os
import sys

TIMINGS_CACHE = "/tmp/prayer_times.json"
LOCATION_CACHE = "/tmp/prayer_location.json"

def get_location():
    today = datetime.date.today().isoformat()
    # Try reading location from cache first (valid for today)
    if os.path.exists(LOCATION_CACHE):
        try:
            with open(LOCATION_CACHE, 'r') as f:
                cached = json.load(f)
                if cached.get("date") == today:
                    return cached.get("lat"), cached.get("lon"), cached.get("city")
        except Exception:
            pass

    # Request geolocation data based on IP
    try:
        req = urllib.request.Request(
            "http://ip-api.com/json",
            headers={"User-Agent": "Mozilla/5.0"}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            lat = data.get("lat")
            lon = data.get("lon")
            city = data.get("city")
            
            if lat and lon:
                # Save to cache
                with open(LOCATION_CACHE, 'w') as f:
                    json.dump({"date": today, "lat": lat, "lon": lon, "city": city}, f)
                return lat, lon, city
    except Exception:
        pass
        
    # Fallback to Cairo if geolocation fails
    return 30.0444, 31.2357, "Cairo"

def get_prayer_timings(lat, lon):
    today = datetime.date.today().isoformat()
    # Try reading timings from cache first
    if os.path.exists(TIMINGS_CACHE):
        try:
            with open(TIMINGS_CACHE, 'r') as f:
                cached = json.load(f)
                if cached.get("date") == today:
                    return cached.get("timings")
        except Exception:
            pass

    # Fetch from API using Egypt survey method (method=5)
    try:
        url = f"http://api.aladhan.com/v1/timings?latitude={lat}&longitude={lon}&method=5"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=5) as response:
            res = json.loads(response.read().decode())
            timings = res["data"]["timings"]
            # Save to cache
            with open(TIMINGS_CACHE, 'w') as f:
                json.dump({"date": today, "timings": timings}, f)
            return timings
    except Exception:
        # Fallback to older cache if available
        if os.path.exists(TIMINGS_CACHE):
            try:
                with open(TIMINGS_CACHE, 'r') as f:
                    return json.load(f).get("timings")
            except Exception:
                pass
        return None

def parse_time(time_str):
    parts = time_str.split(":")
    return int(parts[0]), int(parts[1])

def main():
    lat, lon, city = get_location()
    timings = get_prayer_timings(lat, lon)
    if not timings:
        print("No timings")
        sys.exit(0)

    # We want Fajr, Dhuhr, Asr, Maghrib, Isha
    prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    now = datetime.datetime.now()
    
    # Parse prayer times for today
    prayer_times = []
    for p in prayers:
        t_str = timings.get(p)
        if not t_str:
            continue
        h, m = parse_time(t_str)
        p_time = now.replace(hour=h, minute=m, second=0, microsecond=0)
        prayer_times.append((p, p_time))

    # Find the next prayer
    next_p = None
    next_p_time = None

    for name, p_time in prayer_times:
        if p_time > now:
            next_p = name
            next_p_time = p_time
            break

    # If all prayers today have passed, the next one is Fajr tomorrow
    if not next_p:
        next_p = "Fajr"
        f_str = timings.get("Fajr")
        h, m = parse_time(f_str)
        next_p_time = now.replace(hour=h, minute=m, second=0, microsecond=0) + datetime.timedelta(days=1)

    # Calculate remaining time
    diff = next_p_time - now
    diff_seconds = diff.total_seconds()
    hours = int(diff_seconds // 3600)
    minutes = int((diff_seconds % 3600) // 60)
    seconds = int(diff_seconds % 60)

    next_p_time_str = next_p_time.strftime("%I:%M %p").lstrip('0')
    # Format output: e.g. "Dhuhr in 2:51:15 (12:04 PM)"
    print(f"{next_p} in {hours}:{minutes:02d}:{seconds:02d} ({next_p_time_str})")

if __name__ == "__main__":
    main()

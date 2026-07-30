#!/usr/bin/env python3
# =============================================================================
#   CachyOS & HyDE Unified Task Manager CLI & GUI Launcher
#   Part of: CachyOS + HyDE System Restorer
# =============================================================================

import sys
import os
import subprocess

TASKS_FILE = os.path.expanduser("~/.config/fastfetch/tasks.txt")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GUI_SCRIPT = os.path.join(SCRIPT_DIR, "task-manager-gui.py")

def read_tasks():
    if not os.path.exists(TASKS_FILE):
        return []
    with open(TASKS_FILE, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def write_tasks(tasks):
    os.makedirs(os.path.dirname(TASKS_FILE), exist_ok=True)
    with open(TASKS_FILE, 'w') as f:
        for t in tasks:
            f.write(t + "\n")

def select_task_interactively(tasks, prompt_text="Select Task: "):
    # Try fzf first in terminal
    if sys.stdin.isatty():
        try:
            p = subprocess.Popen(['fzf', f'--prompt={prompt_text}'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
            out, _ = p.communicate(input='\n'.join(tasks))
            if p.returncode == 0 and out.strip():
                return out.strip()
        except Exception:
            pass

    # Fallback to rofi if available
    try:
        p = subprocess.Popen(['rofi', '-dmenu', '-i', '-p', prompt_text], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        out, _ = p.communicate(input='\n'.join(tasks))
        if p.returncode == 0 and out.strip():
            return out.strip()
    except Exception:
        pass

    return None

def add_or_update(task_text, new_prefix):
    tasks = read_tasks()
    found = False
    new_tasks = []
    cleaned_query = task_text.strip().lower()
    
    for t in tasks:
        content = t
        for pfx in ["[ ]", "[/]", "[x]", "- "]:
            if t.startswith(pfx):
                content = t[len(pfx):].strip()
                break
        
        if content.lower() == cleaned_query:
            new_tasks.append(f"{new_prefix} {content}")
            found = True
        else:
            new_tasks.append(t)
            
    if not found:
        new_tasks.append(f"{new_prefix} {task_text.strip()}")
        
    write_tasks(new_tasks)

def launch_gui(mode="all"):
    if os.path.exists(GUI_SCRIPT) and (os.environ.get('WAYLAND_DISPLAY') or os.environ.get('DISPLAY')):
        subprocess.run([sys.executable, GUI_SCRIPT, mode])
    elif os.path.exists(os.path.expanduser("~/.local/share/bin/task-manager-gui.py")):
        subprocess.run([sys.executable, os.path.expanduser("~/.local/share/bin/task-manager-gui.py"), mode])
    else:
        editor = os.environ.get("EDITOR", "nano")
        subprocess.run([editor, TASKS_FILE])

def handle_action(action, args):
    tasks = read_tasks()
    
    if action == "todo":
        if not args:
            launch_gui("todo")
        else:
            add_or_update(' '.join(args), "[ ]")
            
    elif action in ["doing", "done", "remove", "edit"]:
        if args:
            prefix_map = {"doing": "[/]", "done": "[x]"}
            if action in prefix_map:
                add_or_update(' '.join(args), prefix_map[action])
        else:
            # Interactive selection
            sel = select_task_interactively(tasks, f"Select Task for {action.upper()}: ")
            if sel:
                if action == "doing":
                    add_or_update(sel, "[/]")
                elif action == "done":
                    add_or_update(sel, "[x]")
                elif action == "remove":
                    new_t = [t for t in tasks if t != sel]
                    write_tasks(new_t)
                elif action == "edit":
                    launch_gui("edit")
            else:
                launch_gui(action)

def main():
    if len(sys.argv) < 2:
        launch_gui("all")
        sys.exit(0)
        
    action = sys.argv[1]
    args = sys.argv[2:]
    
    handle_action(action, args)

if __name__ == "__main__":
    main()

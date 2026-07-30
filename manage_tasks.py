#!/usr/bin/env python3
# =============================================================================
#   CachyOS & HyDE Terminal-Native Task Manager (fzf / CLI Menu)
#   Part of: CachyOS + HyDE System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
# =============================================================================

import sys
import os
import subprocess

TASKS_FILE = os.path.expanduser("~/.config/fastfetch/tasks.txt")

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

def select_task_with_fzf(tasks, action_name):
    if not tasks:
        print("No tasks found in ~/.config/fastfetch/tasks.txt.")
        return None

    header_text = f"=== Task Manager [{action_name.upper()}] ==="
    prompt_text = "Select Task > "

    # 1. Primary: Terminal fzf picker
    try:
        cmd = [
            'fzf',
            '--height=40%',
            '--layout=reverse',
            '--border=rounded',
            f'--header={header_text}',
            f'--prompt={prompt_text}'
        ]
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        out, _ = p.communicate(input='\n'.join(tasks))
        if p.returncode == 0 and out.strip():
            return out.strip()
    except Exception:
        pass

    # 2. Fallback: Terminal CLI Numbered Selection
    print(f"\n\033[1;36m=== Task Selection [{action_name.upper()}] ===\033[0m")
    for i, t in enumerate(tasks, 1):
        print(f"  \033[1;33m[{i}]\033[0m {t}")
    try:
        choice = input("\nEnter choice number (or press Enter to cancel): ").strip()
        if choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(tasks):
                return tasks[idx]
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

def edit_task_cli(task_to_edit):
    content = task_to_edit
    pfx_found = "[ ]"
    for pfx in ["[ ]", "[/]", "[x]", "- "]:
        if task_to_edit.startswith(pfx):
            pfx_found = pfx
            content = task_to_edit[len(pfx):].strip()
            break
            
    try:
        new_text = input(f"\nEdit Task [{content}]: ").strip()
        if new_text:
            tasks = read_tasks()
            new_tasks = []
            for t in tasks:
                if t == task_to_edit:
                    new_tasks.append(f"{pfx_found} {new_text}")
                else:
                    new_tasks.append(t)
            write_tasks(new_tasks)
    except Exception:
        pass

def handle_action(action, args):
    tasks = read_tasks()
    
    if action == "todo":
        if not args:
            try:
                new_t = input("\nEnter new todo task text: ").strip()
                if new_t:
                    add_or_update(new_t, "[ ]")
            except Exception:
                pass
        else:
            add_or_update(' '.join(args), "[ ]")
            
    elif action in ["doing", "done", "remove", "edit"]:
        if args:
            prefix_map = {"doing": "[/]", "done": "[x]"}
            if action in prefix_map:
                add_or_update(' '.join(args), prefix_map[action])
        else:
            # Terminal-native fzf selection
            sel = select_task_with_fzf(tasks, action)
            if sel:
                if action == "doing":
                    add_or_update(sel, "[/]")
                elif action == "done":
                    add_or_update(sel, "[x]")
                elif action == "remove":
                    new_t = [t for t in tasks if t != sel]
                    write_tasks(new_t)
                elif action == "edit":
                    edit_task_cli(sel)

    # Refresh Fastfetch output after action if in interactive terminal
    if sys.stdin.isatty():
        try:
            subprocess.run(['fastfetch'])
        except Exception:
            pass

def main():
    if len(sys.argv) < 2:
        tasks = read_tasks()
        sel = select_task_with_fzf(tasks, "manage")
        if sel:
            add_or_update(sel, "[/]")
        sys.exit(0)
        
    action = sys.argv[1]
    args = sys.argv[2:]
    
    handle_action(action, args)

if __name__ == "__main__":
    main()

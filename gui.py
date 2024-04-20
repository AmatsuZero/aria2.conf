from configparser import ConfigParser
import os
import subprocess

config = ConfigParser()
config_path = os.path.join(os.getcwd(), "aria2.local.conf")
config.read(config_path)

def command(args: list[str]) -> str:
    return subprocess.check_output(args).decode('utf-8').strip()

def read_conf() -> str:
    args = [
        'zenity', '--list', '--title=aria2 配置文件修改',
        '--editable', '--column=配置', '--column=值',
    ]

    for section in config.sections():
        items = config.items(section)
        for (key, val) in items:
            # 这里感觉是 zenity 的 bug，不加引号，执行会报错
            args.append(f'"{key}"' if '-' in key else key)
            args.append(f'"{val}"' if '-' in val else val)

    return command(args)

def change_dir(opt: str):
    dir = command([
        'zenity', '--file-selection', f'--title=修改选项: {opt}', '--directory'
    ])
    config['local'][opt] = dir

def change_conf(opt: str):
    conf = command([
        'zenity', '--entry', f'--title=修改选项: {opt}',
        '--entry-text', config['local'][opt],
    ])
    
    if conf:
        config['local'][opt] = conf

def change_file(opt: str):
    file = command([
        'zenity', '--file-selection', f'--title=修改选项: {opt}',
    ])
    config['local'][opt] = file

def change_flag(opt: str):
    flag = command([
        'zenity', '--list', f'--title=修改选项: {opt}', '--radiolist',
        '--column=ID', '--column=状态', '1', 'true', '2', 'false'
    ])
    config['local'][opt] = flag

# 生成配置
def generate_conf_map():
    m = {
        'dir': change_dir,
        'input-file': change_file,
        'save-session': change_file,
        'dht-file-path': change_file,
        'dht-file-path6': change_file,
        'on-download-stop': change_file,
        'on-download-complete': change_file,
    }
    items = config.items('local')
    for (key, val) in items:
        if val == 'true' or val == 'false':
            m[key] = change_flag

    return m

conf_map = generate_conf_map()

def trim_space():
    # first get all lines from file
    with open(config_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # remove spaces
    lines = [line.replace(' ', '') for line in lines]

    # finally, write lines in the file
    with open(config_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)

try:
    opt = read_conf()
    # 去掉引号
    opt = opt.replace("\"", "")
    if opt in conf_map:
        conf_map[opt](opt)
    else:
        change_conf(opt)
    
    # 写配置
    with open(config_path, 'w', encoding='utf-8') as configfile:
        config.write(configfile)
    
    # 干掉空格，不然脚本读取会有问题
    trim_space()
except subprocess.CalledProcessError as e:
    print(e.output)
    
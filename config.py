from configparser import ConfigParser
import os

config = ConfigParser()
config_path = os.path.join(os.getcwd(), "aria2.conf")
config.read(config_path)

output = f"""
    zenity --forms --title="aria2 配置文件修改\n"
"""

for section in config.sections:
    output += f'--text={section}\n'
    # 获取该 section 下面所有的键值对
    items = config.items(section)
    for item in items:
        output += f'--add-entry="{item}"\n'
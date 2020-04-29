#!/usr/bin/python
# -*- coding: utf-8 -*-
#form ios
import os
import sys
import gzip
import shutil

# Python2.5 初始化后会删除 sys.setdefaultencoding 这个方法，我们需要重新载入
# 可能带来的坑: https://blog.ernest.me/post/python-setdefaultencoding-unicode-bytes
reload(sys)    
sys.setdefaultencoding('utf-8')  

# 删除文件
def rm_file(file_path):
    if os.path.exists(file_path):
        if os.path.isfile(file_path):
            os.remove(file_path)
        else:
            os.rmdir(file_path)

# 解压文件
def unzip(filePath, targetPath = './'):  
    fileName = os.path.splitext(os.path.basename(filePath))[0]

    # 创建文件夹
    if not os.path.isdir(targetPath):  
        os.mkdir(targetPath)   

    # 删除历史的
    extract_path = targetPath + "/" + fileName
    if os.path.exists(extract_path):
        shutil.rmtree(extract_path)
    
    # 解压每一项
    zip_file = zipfile.ZipFile(filePath)  
    for names in zip_file.namelist():  
        zip_file.extract(names, extract_path + "/")  
    zip_file.close()

    return extract_path

# 移动文件
def func_file_move(sourcePath,targetPath):
    if not os.path.exists(sourcePath):
        # print('源文件不存在:' + sourcePath)
        return
        pass

    if os.path.isdir(sourcePath):
        os.mkdir(targetPath)
        pass
    shutil.move(sourcePath,targetPath) 

# 输入目录路径，输出最新文件完整路径
def find_new_file(dir):
    '''查找目录下最新的文件'''
    file_list = os.listdir(dir)
    log_file_list = []
    for tmp_file in file_list:
        # os.path.splitext():分离文件名与扩展名
        if os.path.splitext(tmp_file)[1] == '.xcactivitylog':
            log_file_list.append(tmp_file)
    print 'log列表: ',log_file_list

    log_file_list.sort(key=lambda fn: os.path.getmtime(dir + "/" + fn)
                     if not os.path.isdir(dir + "/" + fn) else 0)
    print '最新的文件为： ' + log_file_list[-1]
    file = os.path.join(dir, log_file_list[-1])
    print '完整路径：'+ file
    return file

if __name__ == "__main__":

    LOGS_DIR = sys.argv[1]
    FILE_PATH = sys.argv[2]
    PROJECT_PATH = sys.argv[3]
    TEMP_FILE_PATH = sys.argv[4]
    ARCH = sys.argv[5]


    print 'LOGS_DIR : '+LOGS_DIR
    print 'FILE_PATH : '+FILE_PATH
    print 'PROJECT_PATH : '+PROJECT_PATH
    print 'TEMP_FILE_PATH : '+TEMP_FILE_PATH

    log_path = find_new_file(LOGS_DIR)

    with gzip.open(log_path,'rt') as f:
        read_content = f.read()
    read_lines = read_content.splitlines()
    print len(read_lines)
    for tmp_line in read_lines:
        #if FILE_PATH in tmp_line and ' -o ' in tmp_line and 'clang' in tmp_line and ARCH in tmp_line
        if FILE_PATH in tmp_line and '-arch '+ ARCH in tmp_line:
            splitArray = tmp_line.split(' -o ')
            compile_command = splitArray[0]

    if '-fvisibility=hidden' in compile_command:
        print "compile_command has -fvisibility=hidden,replace it with blank"
        compile_command = compile_command.replace('-fvisibility=hidden','')

    print "compile_command : "+compile_command
    compile_command = "cd " + PROJECT_PATH + " && " + compile_command

    if not os.path.exists(os.path.dirname(TEMP_FILE_PATH)):
        print os.path.dirname(TEMP_FILE_PATH)
        os.makedirs(os.path.dirname(TEMP_FILE_PATH))

    outfile = open(TEMP_FILE_PATH,'w')
    outfile.writelines(compile_command)
    outfile.close()

    sys.exit()

#!/usr/bin/env python
# -*- coding: utf-8 -*-
#cython: language_level=3
import os
from setuptools import setup, find_packages, Extension
from files_list import open_config
from copy import deepcopy
from os.path import dirname, join, sep
from os import environ

src_path = build_path = dirname(__file__)

def read(file_path):
    with open(file_path) as fp:
        return fp.read()

def determine_base_flags():
    flags = {
        'include_dirs': [],
        'library_dirs': [],
        'extra_link_args': [],
        'extra_compile_args': []}

    sysroot = environ.get('IOSSDKROOT', environ.get('SDKROOT'))
    if not sysroot:
        raise Exception('IOSSDKROOT is not set')
    flags['include_dirs'] += [sysroot]
    flags['extra_compile_args'] += ['-isysroot', sysroot]
    flags['extra_link_args'] += ['-isysroot', sysroot]

    return flags

def merge(d1, *args):
    d1 = deepcopy(d1)
    for d2 in args:
        for key, value in d2.items():
            value = deepcopy(value)
            if key in d1:
                d1[key].extend(value)
            else:
                d1[key] = value
    return d1

def expand(root, *args):
    return join(root, *args)

class CythonExtension(Extension):

    def __init__(self, *args, **kwargs):
        Extension.__init__(self, *args, **kwargs)
        self.cython_directives = {
            'c_string_encoding': 'utf-8',
            'profile': 'USE_PROFILE' in environ,
            'embedsignature': 'USE_EMBEDSIGNATURE' in environ}
        # XXX with pip, setuptools is imported before distutils, and change
        # our pyx to c, then, cythonize doesn't happen. So force again our
        # sources
        self.sources = args[1]

def get_extensions_from_sources(sources):
    _ext_modules = []
    for pyx, flags in sources.items():
        module_name = flags['module_name']
        pyx = expand(src_path,pyx)
        depends = [expand(src_path, x) for x in flags.pop('depends', [])]
        f_depends = [x for x in depends if x.rsplit('.', 1)[-1] in ('m')]
        c_depends = [expand(src_path, x) for x in flags.pop('c_depends', [])]
        #module_name = 'PythonSwiftLink'
        #module_name = m_name
        flags_clean = {'depends': depends}
        for key, value in flags.items():
            if len(value):
                flags_clean[key] = value
        _ext_modules.append(CythonExtension(
            module_name, [pyx] + f_depends + c_depends, **flags_clean))
    return _ext_modules

sources = {}
ext_modules = []
src_path = build_path = dirname(__file__)
base_flags = determine_base_flags()

cfg = open_config()
file_list = cfg.items()
for _file in file_list: 
    _deps = _file['depends']
    _classname = _file['classname']
    _filename = _file['dirname']

    osx_flags = {
        'extra_link_args': [],
        #'extra_compile_args': ['-ObjC++'],
        'extra_compile_args': ['-ObjC'],
        'depends': [
                    '%s/%s.m' % (_filename,_filename)
                    ]}
    sources['%s/%s_cy.pyx' % (_filename,_filename)] = merge(base_flags, osx_flags)
    sources['%s/%s_cy.pyx' % (_filename,_filename)]['module_name'] = _classname
# osx_flags = {
#     'extra_link_args': [],
#     #'extra_compile_args': ['-ObjC++'],
#     'extra_compile_args': ['-ObjC'],
#     'depends': [
#                 'LiveOsc.m','LiveOscExt.pxd'
#                 ]}
# sources['LiveOscLib.pyx'] = merge(base_flags, osx_flags)
# sources['LiveOscLib.pyx']['module_name'] = "LiveOscLib"

# osx_flags = {
#     'extra_link_args': [],
#     #'extra_compile_args': ['-ObjC++'],
#     'extra_compile_args': ['-ObjC'],
#     'depends': [
#                 'pythoncalltest.m'
#                 ]}
# sources['pythoncalltest_cy.pyx'] = merge(base_flags, osx_flags)
# sources['pythoncalltest_cy.pyx']['module_name'] = "pythoncalltesta"

ext_modules.extend(get_extensions_from_sources(sources))
 #= get_extensions_from_sources(sources,"LiveOsc")

setup(
      name='PythonSwiftLink',
      version='0.1',
      description="A Cython wrapper for Objc/Swift",
      classifiers=[
                   'Development Status :: 1 - Development',
                   'Intended Audience :: Developers',
                   'Natural Language :: English',
                   'Operating System :: iOS',
                   'Programming Language :: Cython / Objective-C / Swift',
                   'Programming Language :: Python :: 3.7',
                   'Topic :: Payment Processing',
                   ],
      keywords=['PythonSwiftLink'],
      author='GoBig87 / PsycHoWasP',
      author_email='add_later@add)later.com',
      url='',
      license='BSD',
      packages=find_packages(where='.', exclude=['docs', 'tests']),
      ext_modules=ext_modules,
      include_package_data=True,
      zip_safe=False,
      setup_requires=[
                      'setuptools',
                      ],

      )
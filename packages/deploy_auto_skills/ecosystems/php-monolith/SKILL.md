---
name: ecosystem.php-monolith
description: 用于补充传统 PHP 单体系统、自托管管理系统、项目管理系统等场景的识别与部署判断。适用于存在 www、framework、module、db、config 等目录的项目。
category: ecosystem
version: 1.0.0
---

# Skill: ecosystem.php-monolith

## Purpose

帮助 Agent 识别传统 PHP 单体系统，避免简单退化成静态站点或通用 Node/Python 服务。

## Trigger Signals

1. 仓库中存在典型 PHP 单体目录结构
2. 项目是管理系统、CMS、项目管理系统等自托管产品
3. 文档中出现 PHP 安装、Web 服务器、数据库初始化说明

## Required Evidence

1. 典型 PHP 单体目录结构，如 `www/`、`framework/`、`module/`、`db/`
2. `composer.json`、Web 服务器配置和数据库初始化文件
3. 文档中的 PHP、Apache / Nginx、数据库说明
4. 现有 Dockerfile、Compose 或安装脚本

## Analysis Steps

1. 先看是否存在官方部署文档或脚本
2. 再看 Web 根目录和配置目录
3. 再看数据库初始化和环境要求

## Decision Hints

1. PHP 单体系统通常是完整应用，不应误判成静态前端
2. 需要同时关注 Web 服务器、PHP 运行时和数据库
3. 若仓库自带 Dockerfile、Compose 或安装脚本，应优先复用

## Risk Guards

1. 不要忽略数据库初始化要求
2. 不要把 PHP 单体误简化成单个进程服务

## Stop Conditions

1. 数据库依赖和初始化方式不清晰
2. 安装步骤复杂且文档不完整

## Output Hints

1. `activeSkills` 应包含 `ecosystem.php-monolith`
2. `risks` 应记录数据库初始化、Web 服务器和 PHP 运行时依赖
3. `requiresManualReview` 可在安装链过长时提升

## Related Skills

1. `artifact.web-service`
2. `entrypoint.readme`
3. `guard.reuse-official-config-first`

---
name: git-workflow
description: >-
  Управляет ветками (GitFlow / Trunk-Based), разрешает конфликты мержа, пишет семантические коммиты (Conventional Commits).
---

# Работа с Git (Git Workflow)

Данный навык поддерживает прозрачную и структурированную историю контроля версий.

## Стандарт Conventional Commits
```text
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```
Типы: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`.

## Принципы работы
1. **Атомарные коммиты**: один коммит — одно логическое изменение.
2. **Чистая история**: использование `git rebase` перед вливанием для исключения бессмысленных merge-коммитов.
3. **Защита веток**: ветка `main` защищена, изменения только через пулл-реквесты с прохождением CI.

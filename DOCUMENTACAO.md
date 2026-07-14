# Chronicle — Documentação técnica

## Visão geral

Chronicle é um aplicativo Flutter para registrar momentos de viagem. Cada
momento pode conter título, descrição, data e hora, humor, fotos e localização.
Os momentos são organizados em álbuns.

## Plataformas

O projeto possui suporte para:

- Windows;
- Android e iOS;
- Chrome/Web.

### Persistência por plataforma

| Plataforma | Implementação | Armazenamento |
| --- | --- | --- |
| Android/iOS | `sqflite` | SQLite nativo |
| Windows | `sqflite_common_ffi` | Arquivo SQLite local |
| Chrome/Web | `sqflite_common_ffi_web` | SQLite WASM persistido no IndexedDB |

No navegador, os dados pertencem à origem da página. Alterar domínio, protocolo
ou porta cria outro espaço de armazenamento no IndexedDB.

## Regras de negócio

### Álbum obrigatório

Um momento novo somente pode ser salvo quando um álbum válido estiver
selecionado.

- A opção "Sem álbum" não é apresentada.
- Se nenhum álbum estiver selecionado, o salvamento é interrompido.
- O usuário recebe a mensagem: `Selecione um álbum para o momento.`

Registros antigos podem continuar sem álbum caso o álbum relacionado tenha sido
excluído. Essa compatibilidade é mantida pelo banco para não perder dados
existentes.

### Localização opcional

A localização não é obrigatória.

- O momento pode ser salvo com o campo vazio.
- O aplicativo não solicita GPS automaticamente ao salvar.
- O usuário pode escrever um local manualmente.
- O botão de localização atual continua disponível como ação opcional.

### Fotos

- São permitidas até seis fotos por momento.
- As imagens são armazenadas como bytes no SQLite.
- Cada imagem pode ter no máximo 12 MB.
- A leitura das fotos selecionadas funciona em desktop, mobile e Web.

## Banco de dados

O banco principal é `chronicle.db`. A abertura e as migrações ficam centralizadas
em `lib/database/database_helper.dart`.

As tabelas principais são:

- `albuns`: dados dos álbuns;
- `registros`: dados dos momentos;
- `fotos`: imagens relacionadas aos momentos.

Na primeira execução são criados quatro álbuns:

- Inverno;
- Verão;
- Outono;
- Primavera.

## Configuração do Chrome

O suporte SQLite no navegador depende destes arquivos versionados em `web/`:

- `web/sqlite3.wasm`;
- `web/sqflite_sw.js`.

Se a versão de `sqflite_common_ffi_web` ou `sqlite3` for atualizada, regenere os
arquivos:

```sh
dart run sqflite_common_ffi_web:setup --force
```

O aplicativo Web deve ser servido por HTTP ou HTTPS. Abrir diretamente o
`index.html` pelo sistema de arquivos não é suficiente para executar o worker e
o WebAssembly.

## Instalação

Instale o Flutter e execute na raiz do projeto:

```sh
flutter pub get
```

Versões usadas na última validação:

- Flutter 3.44.5;
- Dart 3.12.2.

## Execução

### Windows

```sh
flutter run -d windows
```

### Chrome

```sh
flutter run -d chrome
```

### Android

```sh
flutter run -d android
```

Para iOS, execute o projeto em um computador macOS com Xcode configurado.

## Builds de produção

### Windows

```sh
flutter build windows --release
```

### Web

```sh
flutter build web --release
```

### Android

```sh
flutter build apk --release
```

### iOS

```sh
flutter build ios --release
```

## Permissões

Android e iOS possuem declarações para:

- câmera;
- galeria de fotos;
- localização durante o uso.

A permissão de localização somente deve ser solicitada quando o usuário acionar
o botão de localização atual.

No navegador, câmera, arquivos e localização dependem das permissões e dos
recursos oferecidos pelo próprio Chrome. Localização normalmente exige HTTPS ou
`localhost`.

## Validação realizada

Na última verificação:

- a análise Dart não encontrou erros de compilação;
- o build Web de produção foi concluído;
- a homepage foi aberta no navegador com o banco Web inicializado e sem erros
  no console;
- o build Windows de produção foi concluído;
- o build Android não foi executado porque o ambiente de validação não possuía
  Android SDK;
- o build iOS não foi executado porque exige macOS e Xcode.

## Observações de manutenção

- Mantenha `sqlite3.wasm` e `sqflite_sw.js` junto do conteúdo publicado da pasta
  `web/`.
- Após alterar dependências, execute `flutter pub get`.
- Após alterar modelos ou tabelas, incremente a versão do banco e implemente a
  migração em `DatabaseHelper`.
- Teste persistência Web sempre usando a mesma origem durante o desenvolvimento.


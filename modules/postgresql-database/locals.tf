# ------------------------------------------------------------------------------
# PostgreSQL Database Module — Locals
# ------------------------------------------------------------------------------

locals {
  databases = {
    for database in var.databases : database.name => {
      name            = database.name
      charset         = database.charset
      collation       = database.collation
      prevent_destroy = database.prevent_destroy
    }
  }

  protected_databases = {
    for name, database in local.databases : name => database
    if database.prevent_destroy
  }

  unprotected_databases = {
    for name, database in local.databases : name => database
    if !database.prevent_destroy
  }

  supported_charsets = [
    "BIG5",
    "EUC_CN",
    "EUC_JP",
    "EUC_KR",
    "EUC_TW",
    "GB18030",
    "GBK",
    "ISO_8859_5",
    "ISO_8859_6",
    "ISO_8859_7",
    "ISO_8859_8",
    "JOHAB",
    "KOI8R",
    "KOI8U",
    "LATIN1",
    "LATIN2",
    "LATIN3",
    "LATIN4",
    "LATIN5",
    "LATIN6",
    "LATIN7",
    "LATIN8",
    "LATIN9",
    "LATIN10",
    "MULE_INTERNAL",
    "SJIS",
    "SHIFT_JIS_2004",
    "SQL_ASCII",
    "UHC",
    "UTF8",
    "WIN866",
    "WIN874",
    "WIN1250",
    "WIN1251",
    "WIN1252",
    "WIN1253",
    "WIN1254",
    "WIN1255",
    "WIN1256",
    "WIN1257",
    "WIN1258",
  ]

  reserved_database_names = [
    "azure_maintenance",
    "azure_sys",
    "postgres",
    "template0",
    "template1",
  ]
}

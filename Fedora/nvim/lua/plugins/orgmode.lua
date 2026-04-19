return {
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
      require('orgmode').setup {
        org_agenda_files = '~/orgfiles/**/*',
        org_default_notes_file = '~/orgfiles/refile.org',

        org_use_property_inheritance = false,
        hyperlinks = {
          sources = {},
        },

        mappings = {
          org = {
            org_open_at_point = '<Leader>oo',
          },
        },

        org_capture_templates = {
          p = {
            description = 'Zadanie Projektowe',
            template = '* TODO %?\n  SCHEDULED: %^t\n  Kontekst: %a\n\n  %x',
            target = '~/orgfiles/projects.org',
          },
          n = {
            description = 'Szybka Notatka',
            template = '* %?\n  %a',
            target = '~/orgfiles/refile.org',
          },
        },
      }

      vim.lsp.enable 'org'
    end,
  },
}

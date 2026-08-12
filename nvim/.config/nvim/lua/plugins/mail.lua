return {
  {
    'yousefakbar/notmuch.nvim',
    cmd = { 'Notmuch', 'NmSearch', 'Inbox', 'ComposeMail', 'NotmuchDrafts' },
    keys = {
      { '<leader>om', '<cmd>Notmuch<cr>', desc = 'Otwórz pocztę' },
      { '<leader>oi', '<cmd>Inbox<cr>', desc = 'Skrzynka odbiorcza' },
      { '<leader>oc', '<cmd>ComposeMail<cr>', desc = 'Nowa wiadomość' },
      { '<leader>od', '<cmd>NotmuchDrafts<cr>', desc = 'Szkice' },
      { '<leader>mo', function() require('notmuch').search_terms 'path:outlook-main/** and tag:inbox' end, desc = 'Inbox: Outlook' },
      { '<leader>mp', function() require('notmuch').search_terms 'path:polsl/** and tag:inbox' end, desc = 'Inbox: Polsl' },
      { '<leader>mk', function() require('notmuch').search_terms 'path:gmail-kazik/** and tag:inbox' end, desc = 'Inbox: Gmail Kazik' },
      { '<leader>ml', function() require('notmuch').search_terms 'path:gmail-swilczek/** and tag:inbox' end, desc = 'Inbox: Gmail Swilczek' },
      { '<leader>mu', function() require('notmuch').search_terms 'path:icloud/** and tag:inbox' end, desc = 'Inbox: iCloud' },
      -- sent
      {
        '<leader>ms',
        function()
          require('notmuch').search_terms 'from:szymonwilczek@outlook.com or from:sw312468@student.polsl.pl or from:kazikwilczek7@gmail.com or from:swilczek.lx@gmail.com or from:szymonwilczek@icloud.com'
        end,
        desc = 'Wysłane (wszystkie)',
      },
    },
    config = function()
      require('notmuch').setup {
        maildir_sync_cmd = 'mbsync -a',
        sync = {
          sync_mode = 'terminal',
        },

        send = {
          send_mode = 'terminal',
        },

        queries = {
          { name = '📥 Wszystkie Nowe (Unified Inbox)', query = 'tag:inbox and tag:unread' },
          { name = '📬 szymonwilczek@outlook.com', query = 'path:outlook-main/** and tag:inbox' },
          { name = '🎓 sw312468@student.polsl.pl', query = 'path:polsl/** and tag:inbox' },
          { name = '✉️  kazikwilczek7@gmail.com', query = 'path:gmail-kazik/** and tag:inbox' },
          { name = '✉️  swilczek.lx@gmail.com', query = 'path:gmail-swilczek/** and tag:inbox' },
          { name = '🍎 szymonwilczek@icloud.com', query = 'path:icloud/** and tag:inbox' },
          { name = '📥 Wszystkie Wiadomości (all)', query = 'tag:inbox' },
          -- sent
          { name = '📤 Wysłane: Outlook', query = 'path:outlook-main/Sent/**' },
          { name = '📤 Wysłane: Polsl', query = 'path:"polsl/Elementy wysłane/**"' },
          { name = '📤 Wysłane: Gmail Kazik', query = 'path:"gmail-kazik/[Gmail]/Wysłane/**"' },
          { name = '📤 Wysłane: Gmail Swilczek', query = 'path:"gmail-swilczek/[Gmail]/Sent Mail/**"' },
          { name = '📤 Wysłane: iCloud', query = 'path:"icloud/Sent Messages/**"' },
        },

        render_html_body = true,
        thread_view_mode = 'threaded',

        drafts = {
          delete_sent = false,
          show_sent_drafts = false,
          auto_open_attachment_window = false,
        },

        keymaps = {
          sendmail = '<C-c><C-c>',
          attachment_window = '<C-c><C-a>',
        },
      }
    end,
  },
}

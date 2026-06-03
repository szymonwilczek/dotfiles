return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  opts = {
    enabled = false,
  },
  keys = {
    {
      '<leader>tm',
      '<cmd>RenderMarkdown buf_toggle<cr>',
      desc = 'Toggle Render Markdown (current buffer)',
      ft = 'markdown',
    },
  },
}

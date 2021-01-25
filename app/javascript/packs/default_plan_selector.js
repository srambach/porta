import React from 'react'
import { render } from 'react-dom'
import { DefaultPlanSelectorWrapper } from 'Applications'

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('default-plan')

  render(<DefaultPlanSelectorWrapper />, container)
})

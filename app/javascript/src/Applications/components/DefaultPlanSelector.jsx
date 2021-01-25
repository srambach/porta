// @flow

import React
// {useState }
  from 'react'

import {
  Select,
  SelectOption,
  SelectVariant
} from '@patternfly/react-core'

import 'Applications/styles/applications.scss'

// const servicePlans = [
//   {disabled: true, id: 'foo', name: 'Select an Application plan'},
//   {disabled: false, id: '0', name: 'Service plan 0'},
//   {disabled: false, id: '1', name: 'Service plan 1'}
// ]

// type ServicePlan = {
//   id: number,
//   name: string,
//   default: boolean
// }

type Props = {}

// const DEFAULT_PRODUCT = { disabled: true, id: 'foo', name: 'Select a Product' }
// const DEFAULT_APP_PLAN = { disabled: true, id: 'foo', name: 'Select an Application Plan' }

// function toFormSelectOption (p: { disabled?: boolean, name: string, id: number }) {
//   return <FormSelectOption isDisabled={p.disabled} key={p.id} value={p.id} label={p.name} />
// }

// function toSelectOption (p: { disabled?: boolean, name: string, id: number }) {
//   return <SelectOption isDisabled={p.disabled} key={p.id} index={p.id} value={p.name} />
// }

const DefaultPlanSelector = (props: Props) => {
  console.log(props)
  console.time('render DefaultPlanSelector')
  // const { buyerId, createApplicationPath, servicePlansAllowed, products, applicationPlans, createApplicationPlanPath } = props

  // const [plan, setPlan] = useState(DEFAULT_APP_PLAN)

  // const availablePlans = applicationPlans.filter(p => p.issuer_id === product.id)

  console.timeEnd('render DefaultPlanSelector')
  return (
    <div>
      adding a typeahead selector here
      <Select variant={SelectVariant.typeahead}>
        <SelectOption>this</SelectOption>
      </Select>
    </div>
  )
}

export { DefaultPlanSelector }

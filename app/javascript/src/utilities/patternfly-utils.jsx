// @flow

import React from 'react'

import {
  FormSelectOption,
  SelectOption,
  SelectOptionObject as ISelectOptionObject
} from '@patternfly/react-core'

interface Record {
  id: string,
  name: string,
  systemName: string
}

type Props = Record & {
  disabled?: boolean,
  className?: string,
  description?: string
}

export const toFormSelectOption = ({ id, name, disabled = false }: Props) => (
  <FormSelectOption isDisabled={disabled} key={id} value={id} label={name} />
)

class SelectOptionObject implements ISelectOptionObject {
  id: string;
  name: string;
  systemName: string;

  constructor (item: Record) {
    this.id = item.id
    this.name = item.name
    this.systemName = item.systemName
  }

  toString (): string {
    return `${this.name} (${this.systemName})`
  }

  compareTo (other: Record): boolean {
    return this.id === other.id
  }
}

export const toSelectOption = ({ id, name, systemName, disabled = false, className, description }: Props) => (
  <SelectOption
    key={id}
    value={new SelectOptionObject({ id, name, systemName })}
    isDisabled={disabled}
    className={className}
    description={description}
  />
)

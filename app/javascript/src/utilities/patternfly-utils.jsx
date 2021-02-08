// @flow

import React from 'react'

import {
  SelectOption,
  SelectOptionObject as ISelectOptionObject
} from '@patternfly/react-core'

interface Record {
  id: string | number,
  name: string,
  description: string | void
}

type Props = Record & {
  disabled?: boolean,
  className?: string,
  description?: string
}

export class SelectOptionObject implements ISelectOptionObject {
  id: string;
  name: string;
  description: string | void; // TODO: use SelectOption's description instead when PF package is up-to-date

  constructor (item: Record) {
    this.id = String(item.id)
    this.name = item.name
    this.description = item.description
  }

  toString (): string {
    return this.description ? `${this.name} (${this.description})` : this.name
  }

  compareTo (other: Record): boolean {
    return this.id === other.id
  }
}

export const toSelectOption = ({ id, name, description, disabled = false, className }: Props) => (
  <SelectOption
    key={id}
    value={new SelectOptionObject({ id, name, description })}
    isDisabled={disabled}
    className={className}
    description={description}
  />
)
